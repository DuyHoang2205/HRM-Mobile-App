import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../../../app/app_shell.dart';

class _LoginUiConstants {
  static const double horizontalPadding = 24;
  static const double inputSpacing = 16;
  static const double sectionSpacing = 32;
  static const double titleSize = 28;
  static const double subtitleSize = 16;
  static const double buttonVerticalPadding = 16;
  static const Color pageBackground = Color(0xFFF6F7FB);
  static const Color primary = Color(0xFF0B2A5B);
  static const Color heading = Color(0xFF0B1B2B);
  static const Color subtitle = Color(0xFF9AA6B2);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed(BuildContext blocContext) {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      blocContext.read<LoginBloc>().add(
        LoginSubmitted(username: username, password: password),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: Scaffold(
        backgroundColor: _LoginUiConstants.pageBackground,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: _LoginUiConstants.horizontalPadding,
            ),
            child: BlocConsumer<LoginBloc, LoginState>(
              listener: (context, state) {
                if (state.status == LoginStatus.success) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AppShell()),
                  );
                } else if (state.status == LoginStatus.failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error ?? 'Login failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoginHeader(),
                    const SizedBox(height: 48),
                    _CredentialsSection(
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      onTogglePasswordVisibility: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      onSubmit: () => _onLoginPressed(context),
                    ),
                    const SizedBox(height: _LoginUiConstants.sectionSpacing),
                    _LoginButton(
                      isLoading: state.status == LoginStatus.loading,
                      onPressed: () => _onLoginPressed(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 60),
        Icon(Icons.lock_outline, size: 80, color: _LoginUiConstants.primary),
        SizedBox(height: 24),
        Text(
          'Chào Mừng',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _LoginUiConstants.titleSize,
            fontWeight: FontWeight.bold,
            color: _LoginUiConstants.heading,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Đăng Nhập',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _LoginUiConstants.subtitleSize,
            color: _LoginUiConstants.subtitle,
          ),
        ),
      ],
    );
  }
}

class _CredentialsSection extends StatelessWidget {
  const _CredentialsSection({
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LoginInputField(
          controller: usernameController,
          labelText: 'Tên Đăng Nhập',
          prefixIcon: const Icon(Icons.person_outline),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: _LoginUiConstants.inputSpacing),
        _LoginInputField(
          controller: passwordController,
          labelText: 'Mật Khẩu',
          prefixIcon: const Icon(Icons.lock_outline),
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: onTogglePasswordVisibility,
          ),
        ),
      ],
    );
  }
}

class _LoginInputField extends StatelessWidget {
  const _LoginInputField({
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String labelText;
  final Widget prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _LoginUiConstants.primary,
        padding: const EdgeInsets.symmetric(
          vertical: _LoginUiConstants.buttonVerticalPadding,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Đăng Nhập',
              style: TextStyle(
                fontSize: _LoginUiConstants.subtitleSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }
}
