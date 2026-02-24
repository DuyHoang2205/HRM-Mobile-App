import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/bloc/login/login_bloc.dart';
import '../../../logic/bloc/login/login_event.dart';
import '../../../logic/bloc/login/login_state.dart';
import '../../../app/app_shell.dart';

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
        backgroundColor: const Color(0xFFF6F7FB),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Color(0xFF0B2A5B),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Chào Mừng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1B2B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng Nhập',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9AA6B2),
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Tên Đăng Nhập',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật Khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onLoginPressed(context),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed:
                          state.status == LoginStatus.loading ? null : () => _onLoginPressed(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B2A5B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state.status == LoginStatus.loading
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
