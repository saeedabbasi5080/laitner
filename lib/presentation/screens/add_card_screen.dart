import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/add_card/add_card_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddCardCubit>(param1: deckId),
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
  late final TextEditingController _frontController;
  late final TextEditingController _backController;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController();
    _backController = TextEditingController();
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

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AddCardCubit, AddCardState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleIconButton(
                              back: true,
                              icon: Icons.arrow_back,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionLabel(AppStrings.newCard),
                                  SizedBox(height: 4),
                                  Text(
                                    AppStrings.deck,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        const SectionLabel(AppStrings.front),
                        const SizedBox(height: 12),
                        _AutoTextField(
                          controller: _frontController,
                          hint: AppStrings.frontHint,
                          autofocus: true,
                          onChanged: context.read<AddCardCubit>().updateFront,
                        ),
                        const SizedBox(height: 48),
                        Divider(color: colors.border, height: 1),
                        const SizedBox(height: 48),
                        const SectionLabel(AppStrings.back),
                        const SizedBox(height: 12),
                        _AutoTextField(
                          controller: _backController,
                          hint: AppStrings.backHint,
                          onChanged: context.read<AddCardCubit>().updateBack,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.9),
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          AppStrings.cancel,
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: state.canSave
                              ? () async {
                                  final saved =
                                      await context.read<AddCardCubit>().save();
                                  if (saved && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            foregroundColor: const Color(0xFF1A1D24),
                            disabledBackgroundColor:
                                context.accentColor.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            AppStrings.saveCard,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AutoTextField extends StatelessWidget {
  const _AutoTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      maxLines: null,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: context.recallColors.mutedForeground.withValues(alpha: 0.5),
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
