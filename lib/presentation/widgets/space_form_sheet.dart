import 'package:flutter/material.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class SpaceFormSheet extends StatefulWidget {
  const SpaceFormSheet({
    super.key,
    required this.onSubmit,
    this.space,
  });

  final Future<void> Function(String name, DeckColor color) onSubmit;
  final LearningSpace? space;

  bool get isEditing => space != null;

  @override
  State<SpaceFormSheet> createState() => _SpaceFormSheetState();
}

class _SpaceFormSheetState extends State<SpaceFormSheet> {
  late final TextEditingController _nameController;
  late DeckColor _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.space?.name ?? '');
    _color = widget.space?.color ?? DeckColor.lavender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_nameController.text.trim(), _color);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final canSave = _nameController.text.trim().isNotEmpty && !_saving;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isEditing
                          ? AppStrings.editSpace
                          : AppStrings.newSpace,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.muted,
                        foregroundColor: colors.mutedForeground,
                      ),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: AppStrings.spaceName,
                    hintText: AppStrings.spaceNameHint,
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel(AppStrings.accentColor),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: pastelColors.map((name) {
                    final color = DeckColor.fromString(name);
                    final selected = _color == color;
                    final fill = AppColors.forDeck(color);
                    return GestureDetector(
                      onTap: _saving
                          ? null
                          : () => setState(() => _color = color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: fill,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : colors.border,
                            width: selected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSave ? _submit : null,
                    child: Text(
                      widget.isEditing
                          ? AppStrings.saveChanges
                          : AppStrings.createSpace,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
