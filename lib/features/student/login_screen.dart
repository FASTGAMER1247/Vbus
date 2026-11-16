import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/auth_repository.dart';

/// flow.md C1. Lives under features/student/ only because that's
/// where the "common" flows happen to be grouped in this scaffold —
/// it's actually shared by every role. Consider moving to a
/// features/common/ folder once the manager/driver/admin screens
/// exist, per the folder structure discussed earlier.
///
/// Demo credentials (see data/mock/mock_seed.dart): any seeded name
/// (Sanjay, Dr. Meera Rao, Ramesh K, Priya Nair, Platform Admin) with
/// password "demo".
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _collegeController = TextEditingController(text: 'VJIT');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).login(
            collegeCode: _collegeController.text.trim(),
            username: _usernameController.text,
            password: _passwordController.text,
          );
      // Router redirect (app/router.dart) sends the user to their
      // role's home automatically once authControllerProvider updates.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickFill(String username) {
    _collegeController.text = 'VJIT';
    _usernameController.text = username;
    _passwordController.text = 'demo';
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Campus Transit', style: AppTypography.title),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with your college account',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _collegeController,
                    decoration: const InputDecoration(
                      labelText: 'College',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Log in',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR ONE-TAP DEMO LOGIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.drive_eta, size: 16),
                        label: const Text('Driver: Ramesh'),
                        onPressed: _isLoading ? null : () => _quickFill('Ramesh K'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.business_center, size: 16),
                        label: const Text('Manager: Priya'),
                        onPressed: _isLoading ? null : () => _quickFill('Priya Nair'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.school, size: 16),
                        label: const Text('Student: Sanjay'),
                        onPressed: _isLoading ? null : () => _quickFill('Sanjay'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.security, size: 16),
                        label: const Text('Admin'),
                        onPressed: _isLoading ? null : () => _quickFill('Platform Admin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
