import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/bloc/auth_bloc/auth_bloc.dart';
import '../data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool _obscurePassword = true;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF2D2D2D));
    final iconColor =
        theme.iconTheme.color ??
        (isDark ? Colors.white : const Color(0xFF2D2D2D));
    final cardColor = theme.cardColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E1E1E),
                    const Color(0xFF2D2D2D),
                    const Color(0xFF121212),
                  ]
                : [
                    const Color(0xFFE8E4F3),
                    const Color(0xFFFFF8F0),
                    const Color(0xFFFFE8D6),
                  ],
          ),
        ),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              setState(() => _isProcessing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is Authenticated && !isLogin && _isProcessing) {
              _setDisplayName();
            }
          },
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      
                      // Logo Section
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: cardColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(Icons.spa, size: 50, color: iconColor),
                          ),
                          Positioned(
                            top: -5,
                            right: -5,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB88E),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFB88E,
                                    ).withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'MoodJar',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Capture your calm.',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Toggle Login/Signup
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isLogin = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isLogin
                                        ? cardColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: !isLogin
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: !isLogin
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: !isLogin
                                          ? textColor
                                          : (isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[500]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isLogin = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLogin
                                        ? cardColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: isLogin
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    'Log In',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isLogin
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isLogin
                                          ? textColor
                                          : (isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[500]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Form Fields
                      if (!isLogin) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _usernameController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Username',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Enter a username' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'hello@moodjar.com',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter an email' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                              fontSize: 20,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) =>
                              value!.length < 6 ? 'Password too short' : null,
                        ),
                      ),
                      if (isLogin) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthLoading || _isProcessing) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () async {
                              if (_formKey.currentState!.validate()) {
                                final email = _emailController.text.trim();
                                final password = _passwordController.text.trim();
                                
                                if (isLogin) {
                                  context.read<AuthBloc>().add(
                                    AuthLoginRequested(email, password),
                                  );
                                } else {
                                  setState(() => _isProcessing = true);
                                  context.read<AuthBloc>().add(
                                    AuthSignUpRequested(email, password),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF2D2D2D)
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: isDark
                                        ? const Color(0xFF2D2D2D)
                                        : Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      // Social Login
                      Text(
                        'Or continue with',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2D2D2D),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.g_mobiledata,
                                  color: isDark
                                      ? const Color(0xFF2D2D2D)
                                      : Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'By joining, you agree to our Terms of Service\nand Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setDisplayName() async {
    try {
      final username = _usernameController.text.trim();
      await context.read<AuthRepository>().updateDisplayName(username);
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckRequested());
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting username: $e')),
        );
      }
    }
  }
}
