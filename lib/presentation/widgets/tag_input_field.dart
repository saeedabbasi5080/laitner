import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/tag_utils.dart';
import 'package:recall/domain/entities/card_difficulty.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commitDraft() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      _controller.clear();
      return;
    }
    final parsed = TagUtils.splitInput(text);
    if (parsed.isEmpty) return;
    widget.onChanged(TagUtils.normalize([...widget.tags, ...parsed]));
    _controller.clear();
  }

  /// Taps a suggestion chip. Difficulty lives in the same tag list as any
  /// other label, so picking one simply adds or removes its tag.
  void _toggleDifficulty(CardDifficulty difficulty) {
    final has = widget.tags.contains(difficulty.tag);
    widget.onChanged(
      has
          ? widget.tags.where((tag) => tag != difficulty.tag).toList()
          : TagUtils.normalize([...widget.tags, difficulty.tag]),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty &&
        widget.tags.isNotEmpty) {
      widget.onChanged(widget.tags.sublist(0, widget.tags.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.comma) {
      _commitDraft();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(AppStrings.tags),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final difficulty in CardDifficulty.suggestions)
              ChoiceChip(
                label: Text(difficulty.label),
                selected: widget.tags.contains(difficulty.tag),
                onSelected: (_) => _toggleDifficulty(difficulty),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(color: colors.border.withValues(alpha: 0.7)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in widget.tags)
                InputChip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onDeleted: () {
                    widget.onChanged(
                      widget.tags.where((item) => item != tag).toList(),
                    );
                  },
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 280),
                child: Focus(
                  onKeyEvent: _onKey,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      if (value.endsWith(' ') ||
                          value.endsWith(',') ||
                          value.endsWith('،')) {
                        _commitDraft();
                      }
                    },
                    onSubmitted: (_) => _commitDraft(),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: AppStrings.tagsHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
