import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:recall/core/background/nightly_sync.dart';
import 'package:recall/gate_app.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/usecases/run_daily_excel_feed_usecase.dart';
import 'package:recall/domain/usecases/sync_app_gate_due_usecase.dart';
import 'package:recall/domain/usecases/sync_reminders_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/auth/auth_cubit.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/sync/sync_cubit.dart';
import 'package:recall/presentation/screens/app_shell_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['vazirmatn'], license);
  });
  await configureDependencies();

  // Reminder bodies carry the number of cards waiting, so they are computed
  // here and refreshed whenever the app comes back to the foreground.
  final syncReminders = sl<SyncRemindersUseCase>();
  await syncReminders();
  // The app lock lets everything through when nothing is due today.
  _guard(sl<SyncAppGateDueUseCase>());

  // The daily Excel feed releases at most one day's allowance. Running it
  // before the first frame means the home screen already shows the cards it
  // added, rather than a count that grows a moment later.
  final runDailyFeed = sl<RunDailyExcelFeedUseCase>();
  await _guard(runDailyFeed);

  // Not awaited, deliberately. Looking up a stored session costs a keystore read
  // and at most one request with an eight-second timeout, and a launch that waits
  // for it would sit on a splash screen for as long as the server takes to fail.
  // The cubit starts in [AuthStatus.unknown] and the settings tile shows nothing
  // until this resolves, which is the honest answer for that window anyway.
  _guard(sl<AuthCubit>().restore);

  // Also unawaited, and for the same reason: a launch must not wait on a server.
  // Silent about failure, and it does nothing at all when nobody is signed in.
  _guard(sl<SyncCubit>().autoSync);

  // The 3 a.m. sync, which also runs on the first connection after a night
  // offline. Unawaited: it only hands a job to the system.
  _guard(ensureNightlySyncScheduled);
  _syncWhenConnectionReturns();

  runApp(RecallApp(onResumed: _resume));
}

/// The app lock's entry point: the flashcards shown before a chosen app opens.
///
/// Run by the native `GateActivity` in an engine of its own, so it starts only
/// what the cards need — no sync, no reminders, no auto-sync listeners.
@pragma('vm:entry-point')
Future<void> gateMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const GateApp());
}

/// Syncs the moment the network comes back while the app is running.
///
/// The launch's own attempt fails silently when there is no connection, and
/// nothing else would try again until the app was reopened — so the reviews
/// from days offline would sit on the phone with the network right there.
void _syncWhenConnectionReturns() {
  bool? online;
  Connectivity().onConnectivityChanged.listen(
    (results) {
      final now = results.any((result) => result != ConnectivityResult.none);
      // The first event only reports the state at launch, which the launch sync
      // has already dealt with.
      final cameBack = online == false && now;
      online = now;
      if (cameBack) _guard(() => sl<SyncCubit>().autoSync(force: true));
    },
    onError: (Object error) => debugPrint('Connectivity watch failed: $error'),
  );
}

/// The background jobs, run whenever the app comes back.
///
/// Sequential because each changes what the next works from: a sync can bring in
/// cards, and the feed's releases change the due counts the reminders carry, so the
/// reminders are rebuilt last rather than alongside them. None may crash the app: a
/// corrupt settings blob or an unreadable file should leave the user with a working
/// study screen, not a launch failure.
Future<void> _resume() async {
  // The nightly job writes the sync bookkeeping from its own isolate, and this
  // isolate's preferences are a cache that would not see it.
  await _guard(sl<SharedPreferences>().reload);
  // Then sync, so everything below works from what the server knows rather than from a
  // collection this device may have missed changes to. Throttled inside the cubit:
  // coming back to the app is not a reason to sync if it happened a minute ago.
  await _guard(sl<SyncCubit>().autoSync);
  await _guard(sl<RunDailyExcelFeedUseCase>());
  await _guard(sl<SyncRemindersUseCase>());
  await _guard(sl<SyncAppGateDueUseCase>());
}

Future<void> _guard(Future<void> Function() job) async {
  try {
    await job();
  } catch (error, stack) {
    debugPrint('Recall background job failed: $error\n$stack');
  }
}

class RecallApp extends StatefulWidget {
  const RecallApp({super.key, required this.onResumed});

  final Future<void> Function() onResumed;

  @override
  State<RecallApp> createState() => _RecallAppState();
}

class _RecallAppState extends State<RecallApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Reviews answered while the app was closed shift the due counts, so the
    // queued notifications have to be rebuilt rather than trusted.
    widget.onResumed();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<SettingsCubit>()..load()),
        // Provided but not restored here: `main` already started the lookup
        // without awaiting it, so that this provider would only hand the same
        // cubit to the tree.
        BlocProvider.value(value: sl<AuthCubit>()),
      ],
      // A sign-in is when a new phone gets its cards: sync right away rather
      // than leaving an empty home screen until the app is next opened.
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.isSignedIn != current.isSignedIn && current.isSignedIn,
        listener: (_, __) =>
            _guard(() => sl<SyncCubit>().autoSync(force: true)),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) {
            final isDark = settings.themeMode == ThemeMode.dark;
            final theme = isDark
                ? AppTheme.dark(settings.accent)
                : AppTheme.light(settings.accent);
            _updateSystemUI(isDark, theme.colorScheme.surface);

            return MaterialApp(
              title: AppStrings.appTitle,
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: AppTheme.dark(settings.accent),
              themeMode: settings.themeMode,
              locale: const Locale('fa', 'IR'),
              supportedLocales: const [Locale('fa', 'IR')],
              localizationsDelegates: const [
                FlutterQuillLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return MediaQuery.withClampedTextScaling(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.25,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const AppShellScreen(),
            );
          },
        ),
      ),
    );
  }

  void _updateSystemUI(bool isDark, Color navigationBarColor) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}
