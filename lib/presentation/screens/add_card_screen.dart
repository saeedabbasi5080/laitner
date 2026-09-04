import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/add_card/add_card_cubit.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

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
      create: (_) => sl<AddCardCubit>(param1: deckId, param2: spaceId),
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
                        const AppPageHeader(title: AppStrings.newCard),
                        const SizedBox(height: 24),
                        SoftTextField(
                          controller: _frontController,
                          hint: AppStrings.frontHint,
                          label: AppStrings.front,
                          autofocus: true,
                          maxLines: null,
                          hasError: state.status == AddCardStatus.duplicate,
                          onChanged: context.read<AddCardCubit>().updateFront,
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
                        SoftTextField(
                          controller: _backController,
                          hint: AppStrings.backHint,
                          label: AppStrings.back,
                          maxLines: null,
                          onChanged: context.read<AddCardCubit>().updateBack,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.9),
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
                                  final saved = await context
                                      .read<AddCardCubit>()
                                      .save();
                                  if (!context.mounted) return;
                                  if (saved) {
                                    Navigator.of(context).pop();
                                    return;
                                  }
                                  final message = context
                                      .read<AddCardCubit>()
                                      .state
                                      .errorMessage;
                                  if (message != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor: context.accentColor
                                .withValues(alpha: 0.4),
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
