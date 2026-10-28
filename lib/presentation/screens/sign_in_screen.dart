import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/phone_numbers.dart';
import 'package:recall/presentation/blocs/auth/auth_cubit.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// Sign-in by phone number.
///
/// Two steps in one screen: the number, then the code. Which step is showing is
/// the cubit's business, not this screen's — [AuthCubit] decides, and the screen
/// renders whatever it is told. That is why there is no local `bool _codeSent`
/// here to disagree with it.
///
/// Takes the cubit as a parameter rather than reaching for the service locator.
/// The app already provides one at the root, so this screen is a view of that
/// instance and holds no state of its own about who is signed in — but taking it
/// explicitly is what makes the screen testable with a cubit of the test's own
/// making.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.cubit});

  final AuthCubit? cubit;

  @override
  Widget build(BuildContext context) {
    // Resolved from the tree when not supplied, so the common path — pushed from
    // the settings screen, which sits under the app's provider — needs no
    // argument.
    final resolved = cubit ?? context.read<AuthCubit>();

    return BlocProvider.value(
      value: resolved,
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();

  /// What was typed last, as digits.
  ///
  /// Kept so the complaint under the field can tell "still typing" from "typed
  /// something impossible". Without it the red message would appear under a
  /// half-typed number on every keystroke.
  String _phoneDigits = '';
  String _codeDigits = '';

  @override
  void initState() {
    super.initState();
    // Prefilled from the cubit rather than from a stored preference: the cubit
    // already knows the last number it tried, and it is the only thing that
    // should decide what goes in this box.
    final cubit = context.read<AuthCubit>();
    final known = cubit.state.phoneNumber;
    if (known != null && known.isNotEmpty) {
      _phoneController.text = known;
      _phoneDigits = PhoneNumbers.digitsOnly(known);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  /// Digits only, capped at the real length.
  ///
  /// Filters as the user types rather than on submit: an Iranian keyboard emits
  /// Persian digits, and pasting `0912 123 4567` is normal. Both are folded here
  /// so everything downstream — validation, the request, the display — sees one
  /// form.
  void _onPhoneChanged(String value) {
    final digits = PhoneNumbers.digitsOnly(value);
    final capped = digits.substring(0, digits.length.clamp(0, PhoneNumbers.nationalLength));
    if (capped != _phoneController.text) {
      _phoneController.value = TextEditingValue(
        text: capped,
        selection: TextSelection.collapsed(offset: capped.length),
      );
    }
    if (capped != _phoneDigits) {
      setState(() => _phoneDigits = capped);
    }
  }

  void _onCodeChanged(String value) {
    final digits = PhoneNumbers.digitsOnly(value);
    final capped = digits.substring(0, digits.length.clamp(0, 6));
    if (capped != _codeController.text) {
      _codeController.value = TextEditingValue(
        text: capped,
        selection: TextSelection.collapsed(offset: capped.length),
      );
    }
    if (capped != _codeDigits) {
      setState(() => _codeDigits = capped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final cubit = context.read<AuthCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.signInTitle),
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.isAwaitingCode != current.isAwaitingCode,
        listener: (context, state) {
          // Focus follows the step, so the user is never left typing a number
          // into a box that is no longer the one being asked about.
          if (state.isAwaitingCode) {
            _codeController.clear();
            setState(() => _codeDigits = '');
          } else {
            _phoneFocus.requestFocus();
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.isAwaitingCode)
                    _buildCodeStep(context, state, cubit)
                  else
                    _buildPhoneStep(context, state, cubit),
                  if (state.error != null) ...[
                    const SizedBox(height: 20),
                    _AuthMessage(
                      message: state.error!.message,
                      isWarning: state.error!.failure == AuthFailure.codeExpired ||
                          state.error!.failure == AuthFailure.codeLocked ||
                          state.error!.failure == AuthFailure.cooldown,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!state.isAwaitingCode)
                    Text(
                      AppStrings.signInSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneStep(BuildContext context, AuthState state, AuthCubit cubit) {
    final complete = _phoneDigits.length == PhoneNumbers.nationalLength;
    final valid = PhoneNumbers.isValid(_phoneDigits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.phoneNumber,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.recallColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          onChanged: _onPhoneChanged,
          enabled: !state.isBusy,
          keyboardType: const TextInputType.numberWithOptions(signed: false),
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          inputFormatters: [
            // Nothing here filters: `_onPhoneChanged` already does, and doing it
            // twice would fight the controller over the same text.
            LengthLimitingTextInputFormatter(PhoneNumbers.nationalLength),
          ],
          style: const TextStyle(fontSize: 20, letterSpacing: 4),
          decoration: InputDecoration(
            hintText: AppStrings.phoneNumberHint,
            filled: true,
            fillColor: context.recallColors.card,
            prefixIcon: const Icon(Icons.phone_iphone, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: valid ? (_) => _submitPhone(cubit) : null,
        ),
        // Only complained about once the number is complete and still wrong.
        // A complaint under every keystroke of a valid number is noise.
        if (complete && !valid)
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 4),
            child: Text(
              AppStrings.phoneNumberInvalid,
              style: TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: AppStrings.sendCode,
          isBusy: state.status == AuthStatus.requesting,
          isEnabled: valid && !state.isBusy,
          onPressed: () => _submitPhone(cubit),
        ),
      ],
    );
  }

  Widget _buildCodeStep(BuildContext context, AuthState state, AuthCubit cubit) {
    final complete = _codeDigits.length == 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.codeSent,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.7,
            color: context.recallColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.verificationCode,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.recallColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _codeController,
          autofocus: true,
          onChanged: _onCodeChanged,
          enabled: !state.isBusy,
          keyboardType: const TextInputType.numberWithOptions(signed: false),
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(fontSize: 26, letterSpacing: 10),
          decoration: InputDecoration(
            hintText: AppStrings.verificationCodeHint,
            filled: true,
            fillColor: context.recallColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
              borderSide: BorderSide.none,
            ),
          ),
          // Submitted the moment the sixth digit lands, because a correct code
          // needs no further confirmation and a wrong one will say so.
          onSubmitted: complete ? (_) => _submitCode(cubit, state) : null,
        ),
        if (state.error?.attemptsRemaining != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              AppStrings.attemptsLeft(state.error!.attemptsRemaining!),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: AppStrings.confirm,
          isBusy: state.status == AuthStatus.verifying,
          isEnabled: complete && !state.isBusy,
          onPressed: () => _submitCode(cubit, state),
        ),
        const SizedBox(height: 8),
        _TextButton(
          label: state.countdown > 0
              ? AppStrings.secondsLeft(state.countdown)
              : AppStrings.resendCode,
          isEnabled: state.canResend && !state.isBusy,
          onPressed: () => _resend(cubit, state),
        ),
        const SizedBox(height: 4),
        _TextButton(
          label: AppStrings.changePhoneNumber,
          isEnabled: !state.isBusy,
          onPressed: () => cubit.backToPhoneNumber(),
        ),
      ],
    );
  }

  void _submitPhone(AuthCubit cubit) {
    // The last complaint is dropped before the attempt, so a stale "that number
    // is wrong" does not sit under a field the user has since corrected.
    cubit.clearError();
    cubit.requestCode(_phoneController.text);
  }

  void _submitCode(AuthCubit cubit, AuthState state) {
    final phone = state.phoneNumber ?? _phoneController.text;
    cubit.clearError();
    cubit.verifyCode(phoneNumber: phone, code: _codeController.text);
  }

  void _resend(AuthCubit cubit, AuthState state) {
    final phone = state.phoneNumber ?? _phoneController.text;
    cubit.clearError();
    cubit.requestCode(phone);
  }
}

/// The main action button, which shows a spinner instead of its label while busy.
///
/// A button that dims but keeps its label leaves the user unsure whether the tap
/// registered; a spinner answers that by being visibly different.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isEnabled,
    required this.isBusy,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return FilledButton(
      onPressed: isEnabled && !isBusy ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: accent.withValues(alpha: 0.3),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
      child: isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}

/// A secondary action: no fill, no border, just an accent-coloured word.
class _TextButton extends StatelessWidget {
  const _TextButton({
    required this.label,
    required this.onPressed,
    required this.isEnabled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: accent,
        disabledForegroundColor: context.recallColors.mutedForeground.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

/// A message below the fields.
///
/// Warning styling rather than error styling when the failure is recoverable by
/// waiting — an expired code is not a mistake the user made, and presenting it as
/// one reads as though they had done something wrong.
class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message, this.isWarning = false});

  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final color = isWarning ? colors.accent : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.info_outline : Icons.error_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.6, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
