import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:recall/core/app_gate/app_gate.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/gate/gate_cubit.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/screens/gate_screen.dart';

/// The app the gate screen runs: the cards, in the user's theme, and nothing
/// else of the app. Started by `gateMain` in `main.dart`.
class GateApp extends StatelessWidget {
  const GateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<SettingsCubit>()..load()),
        BlocProvider(
          create: (_) {
            final cubit = sl<GateCubit>()..load();
            // Another chosen app opened while this screen was up.
            sl<AppGatePlatform>().onTargetChanged(cubit.load);
            return cubit;
          },
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            title: AppStrings.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(settings.accent),
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
            home: const GateScreen(),
          );
        },
      ),
    );
  }
}
