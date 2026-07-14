import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class DeckFormSheet extends StatefulWidget {
  const DeckFormSheet({
    super.key,
    required this.onSubmit,
    this.deck,
    this.onDelete,
  });

  final Future<void> Function(String name, DeckColor color) onSubmit;
  final Deck? deck;
  final Future<void> Function()? onDelete;

  bool get isEditing => deck != null;

  @override
  State<DeckFormSheet> createState() => _DeckFormSheetState();
}

class _DeckFormSheetState extends State<DeckFormSheet> {
  late final TextEditingController _nameController;
  late DeckColor _color;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck?.name ?? '');
    _color = widget.deck?.color ?? DeckColor.lavender;
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

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 512),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isEditing
                              ? AppStrings.editDeck
                              : AppStrings.newDeck,
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
                    const SizedBox(height: 16),
                    const SectionLabel(AppStrings.deckName),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      autofocus: !widget.isEditing,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: AppStrings.deckNameHint,
                        filled: true,
                        fillColor: colors.muted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel(AppStrings.accentColor),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: pastelColors.map((name) {
                        final color = DeckColor.fromString(name);
                        final selected = _color == color;
                        return GestureDetector(
                          onTap: () => setState(() => _color = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.forDeck(color),
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: AppColors.forDeck(color),
                                      width: 4,
                                    )
                                  : null,
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
                                  _nameController.text,
                                  _color,
                                );
                                if (context.mounted) Navigator.pop(context);
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          widget.isEditing
                              ? AppStrings.saveChanges
                              : AppStrings.createDeck,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (widget.isEditing && widget.onDelete != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await widget.onDelete!();
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.peach,
                            side: BorderSide(
                              color: AppColors.peach.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            AppStrings.deleteDeck,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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
    );
  }
}

class CardFormSheet extends StatefulWidget {
  const CardFormSheet({
    super.key,
    required this.onSubmit,
    this.front = '',
    this.back = '',
    this.title = AppStrings.editCard,
  });

  final Future<void> Function(String front, String back) onSubmit;
  final String front;
  final String back;
  final String title;

  @override
  State<CardFormSheet> createState() => _CardFormSheetState();
}

class _CardFormSheetState extends State<CardFormSheet> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.front);
    _backController = TextEditingController(text: widget.back);
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final canSave = _frontController.text.trim().isNotEmpty &&
        _backController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 512),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel(AppStrings.front),
                    TextField(
                      controller: _frontController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: AppStrings.frontHint,
                        filled: true,
                        fillColor: colors.muted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel(AppStrings.back),
                    TextField(
                      controller: _backController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: AppStrings.backHint,
                        filled: true,
                        fillColor: colors.muted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(AppStrings.cancel),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: canSave
                              ? () async {
                                  await widget.onSubmit(
                                    _frontController.text,
                                    _backController.text,
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                }
                              : null,
                          child: const Text(AppStrings.saveChanges),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
