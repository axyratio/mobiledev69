import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/google_oauth.dart';
import '../../domain/auth_repository.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/signup_view_model.dart';
import '../widgets/auth_scaffold.dart';

/// Email/password sign-up, plus a "Continue with Google" option that runs
/// the OIDC flow in the system browser (allauth creates the account
/// transparently on first Google sign-in, same as [LoginScreen]'s flow).
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignupViewModel(
        repository: context.read<AuthRepository>(),
        authViewModel: context.read<AuthViewModel>(),
      ),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  String? _termsError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    if (!_agreedToTerms) {
      setState(
        () => _termsError = 'Please agree to the processing of personal data.',
      );
    } else {
      setState(() => _termsError = null);
    }
    if (!formValid || !_agreedToTerms) return;

    await context.read<SignupViewModel>().submit(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    // On success the router's auth guard (listening to AuthViewModel)
    // redirects to Home automatically; on failure the ViewModel's
    // errorMessage is already shown below.
  }

  void _continueWithGoogle() => signInWithGoogle(context);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignupViewModel>();
    final errorMessage = viewModel.errorMessage ?? _termsError;

    return AuthScaffold(
      title: 'Get started',
      onBack: () => context.go('/login'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null) ...[
              Text(
                errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your first name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => (value == null || !value.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) => (value == null || value.length < 8)
                  ? 'Password must be at least 8 characters'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) =>
                        setState(() => _agreedToTerms = value ?? false),
                  ),
                  const Expanded(
                    child: Text('I agree to the processing of Personal data'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: viewModel.isSubmitting ? null : _submit,
              child: viewModel.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign up'),
            ),
            const SizedBox(height: 8),
            AuthFooter(
              dividerLabel: 'Sign up with',
              onGooglePressed: _continueWithGoogle,
              promptText: 'Already have an account?',
              actionText: 'Sign in',
              onActionPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
