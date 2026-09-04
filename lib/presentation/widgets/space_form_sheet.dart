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
    this.onDelete,
    this.canDelete = true,
  });

  final Future<void> Function(String name, DeckColor color) onSubmit;
  final LearningSpace? space;
  final Future<void> Function()? onDelete;
  final bool canDelete;

  bool get isEditing => space != null;

  @override
  State<SpaceFormSheet> createState() => _SpaceFormSheetState();
}

class _SpaceFormSheetState extends State<SpaceFormSheet> {
  late final TextEditingController _nameController;
  late DeckColor _color;

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

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final canSave = _nameController.text.trim().isNotEmpty;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: ColoredBox(
         color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 512,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  color: colors.card,
                   borderRadius:
                       const BorderRadius.vertical(top: Radius.circular(24)),
                   border: Border(top: BorderSide(color: colors.border)),
                   boxShadow: AppShadows.card(context),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
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
                              onPressed: () => Navigator.pop(context),
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
                              onTap: () => setState(() => _color = color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: fill,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
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
                            onPressed: canSave
                                ? () async {
                                    await widget.onSubmit(
                                      _nameController.text.trim(),
                                      _color,
                                    );
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                : null,
                            child: Text(
                              widget.isEditing
                                  ? AppStrings.saveChanges
                                  : AppStrings.createSpace,
                            ),
                          ),
                        ),
                        if (widget.isEditing &&
                            widget.onDelete != null &&
                            widget.canDelete) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await widget.onDelete!();
                                if (context.mounted) Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                              ),
                              child: const Text(AppStrings.deleteSpace),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
