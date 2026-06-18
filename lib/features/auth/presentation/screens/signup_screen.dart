import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_textfield.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isHidden = true;

  final emailController = TextEditingController();

  final passwordController = TextEditingController();
  final authService = AuthService.instance();
  final usernameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.55),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 12,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Create an account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign up to get started.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: usernameController,

                          decoration: const InputDecoration(
                            hintText: 'Username',
                          ),
                        ),

                        const SizedBox(height: 10),

                        CustomTextField(
                          hintText: 'Email',
                          icon: Icons.email_outlined,
                          controller: emailController,
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          hintText: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: isHidden,
                          controller: passwordController,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),

                            onPressed: () {
                              setState(() {
                                isHidden = !isHidden;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await authService.signUp(
                                  email: emailController.text,
                                  password: passwordController.text,
                                  username: usernameController.text,
                                );

                                debugPrint('Signup Success');

                                if (context.mounted) {
                                  context.go('/home');
                                }
                              } catch (e) {
                                debugPrint(e.toString());
                              }
                            },

                            child: const Text('Sign Up'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },

                          child: const Text('Already have an account?'),
                        ),
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
