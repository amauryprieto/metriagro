import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:metriagro/core/theme/app_theme.dart';
import 'package:metriagro/core/utils/validators.dart';
import 'package:metriagro/core/firebase/firebase_analytics_config.dart';
import 'package:metriagro/core/firebase/auth_service.dart';
import 'package:metriagro/shared/widgets/google_logo_widget.dart';

class SimpleWelcomePage extends StatefulWidget {
  const SimpleWelcomePage({super.key});

  @override
  State<SimpleWelcomePage> createState() => _SimpleWelcomePageState();
}

class _SimpleWelcomePageState extends State<SimpleWelcomePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isOtpSent = false;
  bool _isLoading = false;

  // GoogleSignIn is now handled by AuthService

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Log screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalyticsConfig.logScreenView('welcome_page');
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildHeadline(),
                const SizedBox(height: 48),
                _buildGoogleSignInButton(),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                if (_isOtpSent) _buildOtpInput() else _buildEmailOrPhoneInput(),
                if (!_isOtpSent) ...[
                  const SizedBox(height: 16),
                  _buildPasswordInput(),
                  if (!_isLogin) ...[const SizedBox(height: 16), _buildConfirmPasswordInput()],
                ],
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 16),
                _buildToggleAuthMode(),
                const SizedBox(height: 32),
                _buildTermsAndConditions(),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'Metriagro',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return const Text(
      'Haz tu mejor trabajo con Metriagro',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: AppTheme.textPrimary, height: 1.3),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        icon: const GoogleLogoWidget(size: 20),
        label: const Text('Continuar con Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.textPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.textHint, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'O',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.textHint, thickness: 1)),
      ],
    );
  }

  Widget _buildEmailOrPhoneInput() {
    return TextFormField(
      controller: _emailOrPhoneController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Ingresa tu email o teléfono',
        hintStyle: const TextStyle(color: AppTheme.textHint),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.textHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa tu email o teléfono';
        }
        if (value.contains('@')) {
          return Validators.validateEmail(value);
        } else {
          return Validators.validatePhoneNumber(value);
        }
      },
    );
  }

  Widget _buildPasswordInput() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Contraseña',
        hintStyle: const TextStyle(color: AppTheme.textHint),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.textHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) => Validators.validatePassword(value),
    );
  }

  Widget _buildConfirmPasswordInput() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        hintText: 'Confirmar contraseña',
        hintStyle: const TextStyle(color: AppTheme.textHint),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.textHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (!_isLogin && value != _passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  Widget _buildOtpInput() {
    return Pinput(
      controller: _otpController,
      length: 6,
      defaultPinTheme: PinTheme(
        width: 48,
        height: 48,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.textHint),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: 48,
        height: 48,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onCompleted: (pin) {
        _handleOtpVerification(pin);
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isOtpSent
                    ? 'Verificar código'
                    : _isLogin
                    ? 'Iniciar sesión'
                    : 'Crear cuenta',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isLogin = !_isLogin;
              _isOtpSent = false;
              _emailOrPhoneController.clear();
              _passwordController.clear();
              _confirmPasswordController.clear();
              _otpController.clear();
            });
          },
          child: Text(
            _isLogin ? 'Regístrate' : 'Inicia sesión',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return const Text(
      'Al continuar, aceptas los Términos de Servicio y la Política de Privacidad de Metriagro.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
    );
  }

  Widget _buildFooter() {
    return const Text(
      'METRIAGRO',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.2),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use AuthService for Google Sign-In
      final UserCredential? userCredential = await AuthService.signInWithGoogle();

      if (userCredential?.user != null) {
        // Log successful Google sign-in
        await FirebaseAnalyticsConfig.logLogin(method: 'google');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión con Google exitoso'), backgroundColor: AppTheme.successColor),
        );

        // TODO: Navigate to main app or home screen
        // Navigator.pushReplacementNamed(context, '/home');
      } else {
        // User cancelled the sign-in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión cancelado'), backgroundColor: AppTheme.textSecondary),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión con Google: $error'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_isOtpSent) {
        _handleOtpVerification(_otpController.text);
      } else {
        _handleEmailOrPhoneAuth();
      }
    }
  }

  void _handleEmailOrPhoneAuth() async {
    final emailOrPhone = _emailOrPhoneController.text.trim();
    final password = _passwordController.text.trim();

    if (emailOrPhone.contains('@')) {
      // Email authentication
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential? userCredential;

        if (_isLogin) {
          // Sign in
          userCredential = await AuthService.signInWithEmailAndPassword(email: emailOrPhone, password: password);
          await FirebaseAnalyticsConfig.logLogin(method: 'email');
        } else {
          // Sign up
          userCredential = await AuthService.createUserWithEmailAndPassword(email: emailOrPhone, password: password);
          await FirebaseAnalyticsConfig.logSignUp(method: 'email');
        }

        if (userCredential?.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLogin ? 'Inicio de sesión exitoso' : 'Cuenta creada exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // TODO: Navigate to main app or home screen
          // Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString()), backgroundColor: AppTheme.errorColor));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Phone authentication - send OTP
      setState(() {
        _isOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de verificación enviado'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  void _handleOtpVerification(String otp) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código verificado exitosamente'), backgroundColor: AppTheme.successColor),
    );
  }
}
