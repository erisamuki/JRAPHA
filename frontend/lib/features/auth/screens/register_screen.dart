import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../../core/widgets/app_text_field.dart';

const List<Map<String, String>> _roles = [
  {'value': 'reception', 'label': 'Reception'},
  {'value': 'nurse', 'label': 'Nurse'},
  {'value': 'doctor', 'label': 'Doctor'},
  {'value': 'laboratory', 'label': 'Laboratory'},
  {'value': 'pharmacy', 'label': 'Pharmacy'},
  {'value': 'admin', 'label': 'Admin'},
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = _roles.first['value']!;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registration submitted'),
          content: const Text(
            'Your account has been created and is pending admin approval. '
            "You'll be able to sign in once an admin approves your request.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // back to login
              },
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.errorMessage ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Register for JRapha', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Your account will need admin approval before you can sign in.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    AppTextField(
                      controller: _fullNameController,
                      label: 'Full name',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone (optional)',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: _roles
                          .map((r) => DropdownMenuItem(value: r['value'], child: Text(r['label']!)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedRole = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a password';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleRegister,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Register'),
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
