import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/quill_document.dart';
import 'package:recall/core/utils/text_direction_utils.dart';
import 'package:recall/data/utils/card_media_store_factory.dart';
import 'package:recall/domain/entities/card_media.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/local_file_image.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

class CardSideEditor extends StatelessWidget {
  const CardSideEditor({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.media,
    required this.onAttach,
    required this.onRemoveMedia,
    this.hasError = false,
    this.minHeight = 120,
  });

  final String label;
  final String hint;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final List<CardMedia> media;
  final VoidCallback onAttach;
  final ValueChanged<CardMedia> onRemoveMedia;
  final bool hasError;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(label)),
            IconButton(
              tooltip: AppStrings.attachMedia,
              onPressed: onAttach,
              icon: const Icon(Icons.attach_file, size: 20),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(
              color: hasError
                  ? AppColors.danger
                  : colors.border.withValues(alpha: 0.7),
            ),
          ),
          child: QuillEditor.basic(
            controller: controller,
            focusNode: focusNode,
            scrollController: scrollController,
            config: QuillEditorConfig(
              minHeight: minHeight - 24,
              padding: EdgeInsets.zero,
              scrollable: false,
              placeholder: hint,
              textCapitalization: TextCapitalization.sentences,
              customStyles: DefaultStyles(
                paragraph: DefaultTextBlockStyle(
                  TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  HorizontalSpacing.zero,
                  VerticalSpacing.zero,
                  VerticalSpacing.zero,
                  null,
                ),
              ),
            ),
          ),
        ),
        if (media.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in media)
                _EditorMediaChip(
                  media: item,
                  onRemove: () => onRemoveMedia(item),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EditorMediaChip extends StatelessWidget {
  const _EditorMediaChip({required this.media, required this.onRemove});

  final CardMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: media.isImage ? 72 : 120,
          height: 72,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: media.isImage
              ? _ImagePreview(media: media)
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      media.kind == CardMediaKind.voice
                          ? AppStrings.attachVoice
                          : AppStrings.attachAudio,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
        ),
        Positioned(
          top: -8,
          left: -8,
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(28, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 14),
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.media});

  final CardMedia media;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: createCardMediaStore().absolutePath(media),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return const Icon(Icons.image_outlined);
        }
        return localFileImage(path, fit: BoxFit.cover);
      },
    );
  }
}

class CardFormatToolbar extends StatelessWidget {
  const CardFormatToolbar({super.key, required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: QuillSimpleToolbar(
        controller: controller,
        config: const QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showDividers: false,
          showFontFamily: false,
          showFontSize: true,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: false,
          showInlineCode: false,
          showColorButton: true,
          showBackgroundColorButton: false,
          showClearFormat: false,
          showAlignmentButtons: false,
          showHeaderStyle: false,
          showListNumbers: false,
          showListBullets: false,
          showListCheck: false,
          showCodeBlock: false,
          showQuote: false,
          showIndent: false,
          showLink: false,
          showUndo: false,
          showRedo: false,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
        ),
      ),
    );
  }
}

class StudyRichText extends StatefulWidget {
  const StudyRichText({
    super.key,
    required this.plain,
    required this.styleJson,
    required this.fontSize,
  });

  final String plain;
  final String styleJson;
  final double fontSize;

  @override
  State<StudyRichText> createState() => _StudyRichTextState();
}

class _StudyRichTextState extends State<StudyRichText> {
  late QuillController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _controller = _buildController();
  }

  @override
  void didUpdateWidget(covariant StudyRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plain != widget.plain ||
        oldWidget.styleJson != widget.styleJson) {
      _controller.dispose();
      _controller = _buildController();
    }
  }

  QuillController _buildController() {
    return QuillController(
      document: documentFromCardSide(
        plain: widget.plain,
        style: widget.styleJson,
      ),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.styleJson.trim().isEmpty) {
      return Text(
        widget.plain,
        textAlign: TextAlign.center,
        textDirection: textDirectionFor(widget.plain),
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }
    return QuillEditor.basic(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: QuillEditorConfig(
        enableInteractiveSelection: false,
        scrollable: false,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            HorizontalSpacing.zero,
            VerticalSpacing.zero,
            VerticalSpacing.zero,
            null,
          ),
        ),
      ),
    );
  }
}
