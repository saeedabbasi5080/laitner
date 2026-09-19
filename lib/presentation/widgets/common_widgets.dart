import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/learning_space.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.back = false,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool back;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final isDanger = color == AppColors.danger;
    final background =
        isDanger ? scheme.errorContainer : scheme.surfaceContainerLow;
    final foreground = color ??
        (isDanger ? scheme.onErrorContainer : scheme.onSurfaceVariant);
    return Semantics(
      label: label,
      button: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: Material(
          color: background,
          shape: CircleBorder(
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                back ? Icons.arrow_back : icon,
                size: 20,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: context.recallColors.mutedForeground,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.accent = false,
    this.onTap,
  });

  final String label;
  final int value;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final scheme = Theme.of(context).colorScheme;
    final background = accent
        ? scheme.primary
        : colors.card;
    final valueColor = accent
        ? scheme.onPrimary
        : scheme.onSurface;
    final labelColor = accent
        ? scheme.onPrimary.withValues(alpha: 0.75)
        : colors.mutedForeground;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: accent
                ? null
                : Border.all(color: colors.border),
            boxShadow: accent
                ? AppShadows.floating(context)
                : AppShadows.card(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RateButton extends StatelessWidget {
  const RateButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: color.withValues(alpha: 0.60),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border.withValues(alpha: 0.7)),
            boxShadow: AppShadows.card(context),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
  Color? confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

class DeleteDeckDecision {
  const DeleteDeckDecision.deleteCards()
      : deleteCards = true,
        transferToDeckId = null;

  const DeleteDeckDecision.transfer(this.transferToDeckId)
      : deleteCards = false;

  final bool deleteCards;
  final String? transferToDeckId;
}

Future<DeleteDeckDecision?> showDeleteDeckFlow(
  BuildContext context, {
  required List<Deck> otherDecks,
}) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(AppStrings.deleteDeck),
      content: const Text(AppStrings.deleteDeckQuestion),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'transfer'),
          child: const Text(AppStrings.transferDeckCards),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'delete'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text(AppStrings.deleteDeckWithCards),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return null;

  if (choice == 'delete') {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteDeckWithCards,
      message: AppStrings.deleteDeckWithCardsWarning,
    );
    if (confirmed == true) {
      return const DeleteDeckDecision.deleteCards();
    }
    return null;
  }

  if (otherDecks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.noOtherDecksToTransfer)),
    );
    return null;
  }

  final targetId = await showPickDeckDialog(
    context,
    decks: otherDecks,
    title: AppStrings.selectTargetDeck,
  );
  if (targetId == null) return null;
  return DeleteDeckDecision.transfer(targetId);
}

class DeleteSpaceDecision {
  const DeleteSpaceDecision.deleteContent()
      : deleteContent = true,
        transferToSpaceId = null;

  const DeleteSpaceDecision.transfer(this.transferToSpaceId)
      : deleteContent = false;

  final bool deleteContent;
  final String? transferToSpaceId;
}

Future<DeleteSpaceDecision?> showDeleteSpaceFlow(
  BuildContext context, {
  required List<LearningSpace> otherSpaces,
  required int deckCount,
  required int cardCount,
}) async {
  final hasContent = deckCount > 0 || cardCount > 0;

  if (!hasContent) {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteSpace,
      message: AppStrings.deleteEmptySpaceConfirm,
    );
    if (confirmed == true) return const DeleteSpaceDecision.deleteContent();
    return null;
  }

  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(AppStrings.deleteSpace),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.deleteSpaceIntro,
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 12),
            const Text(
              AppStrings.deleteSpaceQuestion,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, 'transfer'),
              child: const Text(AppStrings.transferSpaceCards),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.transferSpaceCardsHint,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text(AppStrings.deleteSpaceWithContent),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || choice == null) return null;

  if (choice == 'delete') {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteSpaceWithContent,
      message: AppStrings.deleteSpaceWithContentWarning,
    );
    if (confirmed == true) {
      return const DeleteSpaceDecision.deleteContent();
    }
    return null;
  }

  if (otherSpaces.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.noOtherSpacesToTransfer)),
    );
    return null;
  }

  final target = await showPickSpaceDialog(
    context,
    spaces: otherSpaces,
    title: AppStrings.selectTargetSpace,
    forcePicker: true,
  );
  if (target == null) return null;
  return DeleteSpaceDecision.transfer(target.id);
}

Future<String?> showPickDeckDialog(
  BuildContext context, {
  required List<Deck> decks,
  String title = AppStrings.selectTargetDeck,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.forDeck(deck.color),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(deck.name),
              onTap: () => Navigator.pop(ctx, deck.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(AppStrings.cancel),
        ),
      ],
    ),
  );
}

Future<LearningSpace?> showPickSpaceDialog(
  BuildContext context, {
  required List<LearningSpace> spaces,
  required String title,
  String Function(LearningSpace space)? subtitle,
  bool forcePicker = false,
}) {
  if (spaces.isEmpty) return Future<LearningSpace?>.value();
  if (!forcePicker && spaces.length == 1) {
    return Future<LearningSpace?>.value(spaces.first);
  }

  return showDialog<LearningSpace>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: spaces.length,
          itemBuilder: (context, index) {
            final space = spaces[index];
            final detail = subtitle?.call(space);
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.forDeck(space.color),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(space.name),
              subtitle: detail == null ? null : Text(detail),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx, space),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(AppStrings.cancel),
        ),
      ],
    ),
  );
}
