import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/permissions/media_permission.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/quill_document.dart';
import 'package:recall/domain/entities/card_media.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/add_card/add_card_cubit.dart';
import 'package:recall/presentation/widgets/card_attach_sheet.dart';
import 'package:recall/presentation/widgets/card_side_editor.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/deck_card_sheets.dart';
import 'package:recall/presentation/widgets/tag_input_field.dart';
import 'package:record/record.dart';

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({
    super.key,
    required this.deckId,
    required this.spaceId,
  });

  final String deckId;
  final String spaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddCardCubit>(param1: deckId, param2: spaceId)
        ..loadDecks(),
      child: const _AddCardView(),
    );
  }
}

class _AddCardView extends StatefulWidget {
  const _AddCardView();

  @override
  State<_AddCardView> createState() => _AddCardViewState();
}

class _AddCardViewState extends State<_AddCardView> {
  late final QuillController _frontController;
  late final QuillController _backController;
  late final FocusNode _frontFocus;
  late final FocusNode _backFocus;
  late final ScrollController _frontScroll;
  late final ScrollController _backScroll;
  late final AudioRecorder _recorder;
  late QuillController _toolbarController;
  bool _isRecording = false;
  CardMediaSide? _recordingSide;

  @override
  void initState() {
    super.initState();
    _frontController = QuillController.basic();
    _backController = QuillController.basic();
    _frontFocus = FocusNode();
    _backFocus = FocusNode();
    _frontScroll = ScrollController();
    _backScroll = ScrollController();
    _recorder = AudioRecorder();
    _toolbarController = _frontController;
    _frontController.addListener(_syncFront);
    _backController.addListener(_syncBack);
    _frontFocus.addListener(_syncToolbarTarget);
    _backFocus.addListener(_syncToolbarTarget);
  }

  @override
  void dispose() {
    _frontController.removeListener(_syncFront);
    _backController.removeListener(_syncBack);
    _frontFocus.removeListener(_syncToolbarTarget);
    _backFocus.removeListener(_syncToolbarTarget);
    _frontController.dispose();
    _backController.dispose();
    _frontFocus.dispose();
    _backFocus.dispose();
    _frontScroll.dispose();
    _backScroll.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _syncFront() {
    context.read<AddCardCubit>().setFront(
      plain: plainFromDocument(_frontController.document),
      style: styleFromDocument(_frontController.document),
    );
  }

  void _syncBack() {
    context.read<AddCardCubit>().setBack(
      plain: plainFromDocument(_backController.document),
      style: styleFromDocument(_backController.document),
    );
  }

  void _syncToolbarTarget() {
    final next = _backFocus.hasFocus ? _backController : _frontController;
    if (!identical(next, _toolbarController)) {
      setState(() => _toolbarController = next);
    }
  }

  Future<void> _save(BuildContext context) async {
    _syncFront();
    _syncBack();
    final cubit = context.read<AddCardCubit>();
    if (!cubit.state.canSave) return;
    final saved = await cubit.save();
    if (!context.mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    final message = cubit.state.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _attach(CardMediaSide side) async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }
    final choice = await showCardAttachSheet(context);
    if (!mounted || choice == null) return;
    if (choice == CardAttachChoice.voice) {
      await _startRecording(side);
      return;
    }
    final picked = await pickCardAttachment(context, choice);
    if (!mounted || picked == null) return;
    final cubit = context.read<AddCardCubit>();
    final ok = picked.bytes != null
        ? await cubit.attachBytes(
            side: side,
            kind: picked.kind,
            bytes: picked.bytes!,
            fileName: picked.fileName,
          )
        : false;
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.mediaAttachFailed)),
      );
    }
  }

  Future<void> _startRecording(CardMediaSide side) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.mediaAttachFailed)),
      );
      return;
    }
    final granted = await ensureMicrophonePermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.mediaPermissionDenied)),
        );
      }
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.mediaPermissionDenied)),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'atilearn_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
      path: path,
    );
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingSide = side;
    });
  }

  Future<void> _stopRecording() async {
    final side = _recordingSide ?? CardMediaSide.front;
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingSide = null;
    });
    if (path == null || path.isEmpty) return;
    final ok = await context.read<AddCardCubit>().attachFile(
      side: side,
      kind: CardMediaKind.voice,
      filePath: path,
      fileName: 'voice.m4a',
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.mediaAttachFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AddCardCubit, AddCardState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      CircleIconButton(
                        back: true,
                        icon: Icons.arrow_back,
                        label: AppStrings.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          AppStrings.newCard,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      CircleIconButton(
                        icon: Icons.check,
                        label: AppStrings.saveCard,
                        color: state.canSave ? context.accentColor : null,
                        onPressed: state.canSave ? () => _save(context) : null,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    children: [
                      const SectionLabel(AppStrings.deck),
                      const SizedBox(height: 8),
                      if (state.decks.isEmpty)
                        Text(
                          AppStrings.noDecksForCard,
                          style: TextStyle(color: colors.mutedForeground),
                        )
                      else
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: state.decks.any((d) => d.id == state.deckId)
                              ? state.deckId
                              : state.decks.first.id,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: state.decks
                              .map(
                                (deck) => DropdownMenuItem(
                                  value: deck.id,
                                  child: Text(deck.name),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            if (id != null) {
                              context.read<AddCardCubit>().selectDeck(id);
                            }
                          },
                        ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DeckFormSheet(
                              onSubmit: (name, color) => context
                                  .read<AddCardCubit>()
                                  .createDeck(name, color),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(AppStrings.createNewDeck),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CardSideEditor(
                        label: AppStrings.front,
                        hint: AppStrings.frontHint,
                        controller: _frontController,
                        focusNode: _frontFocus,
                        scrollController: _frontScroll,
                        media: state.mediaFor(CardMediaSide.front),
                        hasError: state.status == AddCardStatus.duplicate,
                        onAttach: () => _attach(CardMediaSide.front),
                        onRemoveMedia: context.read<AddCardCubit>().removeMedia,
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: state.status == AddCardStatus.duplicate
                                ? AppColors.danger
                                : colors.mutedForeground,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      CardSideEditor(
                        label: AppStrings.back,
                        hint: AppStrings.backHint,
                        controller: _backController,
                        focusNode: _backFocus,
                        scrollController: _backScroll,
                        media: state.mediaFor(CardMediaSide.back),
                        onAttach: () => _attach(CardMediaSide.back),
                        onRemoveMedia: context.read<AddCardCubit>().removeMedia,
                      ),
                      const SizedBox(height: 24),
                      TagInputField(
                        tags: state.tags,
                        onChanged: context.read<AddCardCubit>().setTags,
                      ),
                    ],
                  ),
                ),
                if (_isRecording)
                  Material(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    child: ListTile(
                      leading: const Icon(Icons.stop_circle, color: AppColors.danger),
                      title: const Text(AppStrings.recordingVoice),
                      trailing: TextButton(
                        onPressed: _stopRecording,
                        child: const Text(AppStrings.stopRecording),
                      ),
                      onTap: _stopRecording,
                    ),
                  )
                else
                  CardFormatToolbar(controller: _toolbarController),
              ],
            );
          },
        ),
      ),
    );
  }
}
