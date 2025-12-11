import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:logger/logger.dart';
import '../../controllers/auth_controller.dart';
import 'dart:async';
import '../widgets/loading_widget.dart';
// import '../widgets/error_widget.dart';
// import '../widgets/error_boundary.dart';
// import '../../core/errors/app_exception.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<ShadFormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final authC = Get.find<AuthController>();
  final Logger _logger = Logger();

  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _showBiometricButton = false;
  bool _isPasswordObscure = true;

  @override
  void initState() {
    super.initState();
    _logger.i('LoginPage: Initializing login page');
    _checkBiometricAvailability();
    // Listen to biometric setting changes to update UI
    // Note: Since biometric enabled state is stored in secure storage,
    // we don't need reactive listening here. The UI will check on each login attempt.
  }

  Future<void> _checkBiometricAvailability() async {
    _logger.d('LoginPage: Checking biometric availability...');
    try {
      final available = await authC.isBiometricDeviceAvailable();
      final shouldShow = await authC.shouldShowBiometricLogin();
      final enabled = await authC.isBiometricLoginEnabled();

      _logger.i('LoginPage: Biometric check results:');
      _logger.i('LoginPage: - Device available: $available');
      _logger.i('LoginPage: - Should show button: $shouldShow');
      _logger.i('LoginPage: - User enabled: $enabled');

      if (mounted) {
        setState(() {
          _isBiometricAvailable = available;
          _showBiometricButton = shouldShow;
        });
      }

      _logger.i(
        'LoginPage: Biometric button will ${shouldShow ? 'SHOW' : 'HIDE'}',
      );
    } catch (e, stackTrace) {
      _logger.e('LoginPage: Error checking biometric availability: $e');
      _logger.e('LoginPage: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
          _showBiometricButton = false;
        });
      }
    }
  }

  Future<void> _handleFormSubmit() async {
    _logger.i('LoginPage: === MANUAL LOGIN START ===');

    if (formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);

      final values = formKey.currentState!.value;
      final email = values['email']?.toString().trim() ?? '';
      final password = values['password']?.toString() ?? '';

      _logger.i('LoginPage: Attempting manual login for email: $email');
      _logger.d('LoginPage: Password length: ${password.length} characters');

      try {
        final response = await authC.login(email, password);
        setState(() => _isLoading = false);

        final bool success = response['success'] == true;
        final String message = (response.containsKey('message'))
            ? response['message']?.toString() ??
                  'Gagal Login. Periksa email & password.'
            : 'Gagal Login. Periksa email & password.';

        if (success) {
          _logger.i('LoginPage: === MANUAL LOGIN SUCCESS ===');
          _logger.i('LoginPage: Login successful, navigating to home');
          if (mounted) context.go('/');
        } else {
          _logger.w('LoginPage: === MANUAL LOGIN FAILED ===');
          _logger.w('LoginPage: Login failed - $message');
          if (mounted) {
            ShadToaster.of(context).show(
              ShadToast.destructive(
                title: const Text('Error'),
                description: Text(message),
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        setState(() => _isLoading = false);
        _logger.e('LoginPage: === MANUAL LOGIN ERROR ===');
        _logger.e('LoginPage: Exception: $e');
        _logger.e('LoginPage: Stack trace: $stackTrace');

        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text('Error'),
              description: const Text(
                'Terjadi kesalahan saat login. Silakan coba lagi.',
              ),
            ),
          );
        }
      }
    } else {
      _logger.w('LoginPage: Form validation failed');
    }
  }

  Future<void> _handleBiometricLogin() async {
    _logger.i('LoginPage: === BIOMETRIC LOGIN BUTTON CLICKED ===');

    if (_isLoading) {
      _logger.w(
        'LoginPage: Biometric login already in progress, ignoring click',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success = false;
      String errorMessage = 'Login fingerprint gagal.';

      _logger.i('LoginPage: Starting biometric login process...');

      try {
        _logger.d('LoginPage: Calling authC.loginWithBiometric()');
        success = await authC.loginWithBiometric();

        _logger.i(
          'LoginPage: Biometric auth method completed. Success: $success',
        );

        if (!success) {
          // Provide specific error messages based on conditions
          final deviceAvailable = await authC.isBiometricDeviceAvailable();
          final loginEnabled = await authC.isBiometricLoginEnabled();

          _logger.d('LoginPage: Failure analysis:');
          _logger.d('LoginPage: - Device available: $deviceAvailable');
          _logger.d('LoginPage: - Login enabled: $loginEnabled');

          if (!deviceAvailable) {
            errorMessage = 'Perangkat tidak mendukung autentikasi biometrik.';
            _logger.e('LoginPage: Error - Device does not support biometric');
          } else if (!loginEnabled) {
            errorMessage = 'Login biometrik belum diaktifkan.';
            _logger.e('LoginPage: Error - Biometric login not enabled');
          } else {
            errorMessage =
                'Autentikasi biometrik gagal. Silakan coba lagi atau gunakan login manual.';
            _logger.e('LoginPage: Error - Biometric authentication failed');
          }
        }
      } catch (e, stackTrace) {
        _logger.e('LoginPage: === BIOMETRIC LOGIN EXCEPTION ===');
        _logger.e('LoginPage: Exception type: ${e.runtimeType}');
        _logger.e('LoginPage: Exception message: $e');
        _logger.e('LoginPage: Stack trace: $stackTrace');

        // Handle specific biometric errors
        if (e.toString().contains('NotAvailable') ||
            e.toString().contains('not available')) {
          errorMessage =
              'Biometrik tidak tersedia saat ini. Gunakan login manual.';
          _logger.e('LoginPage: Biometric not available error');
        } else if (e.toString().contains('LockedOut') ||
            e.toString().contains('locked')) {
          errorMessage =
              'Biometrik terkunci karena terlalu banyak percobaan. Tunggu beberapa saat atau gunakan login manual.';
          _logger.e('LoginPage: Biometric locked out error');
        } else if (e.toString().contains('NotEnrolled') ||
            e.toString().contains('enrolled')) {
          errorMessage =
              'Tidak ada sidik jari yang terdaftar. Silakan daftar sidik jari di pengaturan perangkat.';
          _logger.e('LoginPage: Biometric not enrolled error');
        } else {
          errorMessage =
              'Terjadi error saat autentikasi fingerprint: ${e.toString()}';
          _logger.e('LoginPage: Unknown biometric error');
        }
      }

      _logger.i('LoginPage: Final biometric result - Success: $success');

      if (success && mounted) {
        _logger.i('LoginPage: === BIOMETRIC LOGIN SUCCESS ===');
        _logger.i('LoginPage: Login successful, navigating to home');
        context.go('/');
      } else if (mounted && !success) {
        _logger.w('LoginPage: === BIOMETRIC LOGIN FAILED ===');
        _logger.w('LoginPage: Showing error message: $errorMessage');
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Login Gagal'),
            description: Text(errorMessage),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _logger.d(
          'LoginPage: Biometric login process completed, UI state reset',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('LoginPage: Building login page UI');

    return Center(
      child: ShadForm(
        key: formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Aplikasiku',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 40),
                ShadInputFormField(
                  id: 'email',
                  controller: _emailController,
                  label: const Text('Email'),
                  placeholder: const Text('Masukkan email Anda'),
                  // description: const Text(
                  //   'Email Anda yang digunakan untuk login.',
                  // ),
                  leading: const Icon(Icons.email),
                  validator: (v) {
                    if (v.isEmpty) {
                      return 'Email tidak boleh kosong.';
                    }
                    if (!v.contains('@')) {
                      return 'Email harus valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ShadInputFormField(
                  id: 'password',
                  controller: _passwordController,
                  obscureText: _isPasswordObscure,
                  label: const Text('Kata Sandi'),
                  placeholder: const Text('Masukkan kata sandi'),
                  // description: const Text('Minimal 6 karakter.'),
                  leading: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(LucideIcons.lock),
                  ),
                  trailing: ShadButton(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.zero,
                    child: Icon(
                      _isPasswordObscure ? LucideIcons.eyeOff : LucideIcons.eye,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordObscure = !_isPasswordObscure);
                    },
                  ),
                  validator: (v) {
                    if (v.length < 6) {
                      return 'Kata sandi minimal 6 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    onPressed: () => _showForgotPasswordDialog(),
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ShadButton(
                  onPressed: _isLoading ? null : _handleFormSubmit,
                  width: double.infinity,
                  height: 45,
                  child: _isLoading
                      ? const AppLoadingWidget(
                          message: 'Mohon tunggu',
                          type: LoadingType.button,
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 20),
                if (_showBiometricButton)
                  GestureDetector(
                    onTap: _isLoading ? null : _handleBiometricLogin,
                    child: AbsorbPointer(
                      absorbing: _isLoading,
                      child: ShadButton.outline(
                        onPressed: _isLoading ? null : _handleBiometricLogin,
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const AppLoadingWidget(
                                message: 'Mohon tunggu',
                                type: LoadingType.button,
                                color: Colors.blue,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fingerprint, color: Colors.blue),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Masuk dengan Fingerprint',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ShadButton.ghost(
                  onPressed: () => context.go('/register'),
                  width: double.infinity,
                  height: 50,
                  child: const Text('Belum punya akun? Daftar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    _logger.i('LoginPage: Opening forgot password dialog');
    final formKey = GlobalKey<ShadFormState>();
    final emailController = TextEditingController();
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => ShadDialog(
          title: const Text('Lupa Password'),
          description: const Text('Masukkan email untuk dapat token reset.'),
          child: ShadForm(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInputFormField(
                  id: 'email',
                  controller: emailController,
                  label: const Text('Email'),
                  placeholder: const Text('Masukkan email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                      return 'Email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(
                  height: 20,
                ), // Jarak antara form email dan button Kirim Token
              ],
            ),
          ),
          actions: [
            ShadButton.outline(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ShadButton(
              child: isLoading
                  ? const AppLoadingWidget(
                      message: 'Memproses...',
                      type: LoadingType.button,
                    )
                  : const Text('Kirim Token Reset'),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState?.saveAndValidate() ?? false) {
                        setState(() => isLoading = true);
                        _logger.i(
                          'LoginPage: Sending password reset for email: ${emailController.text}',
                        );
                        final result = await authC.forgotPassword(
                          emailController.text,
                        );
                        setState(() => isLoading = false);
                        if (result != null && result['success'] == true) {
                          _logger.i(
                            'LoginPage: Password reset token sent successfully',
                          );
                          Navigator.of(dialogContext).pop();
                          _showResetPasswordDialog(
                            emailController.text,
                            result['reset_token'],
                          );
                        } else {
                          _logger.w(
                            'LoginPage: Failed to send password reset: ${result?['message'] ?? 'Unknown error'}',
                          );
                          ShadToaster.of(context).show(
                            ShadToast.destructive(
                              title: const Text('Error'),
                              description: Text(
                                result?['message'] ??
                                    'Gagal mengirim token reset',
                              ),
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(String email, String token) {
    _logger.i('LoginPage: Opening reset password dialog for email: $email');
    final formKey = GlobalKey<ShadFormState>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isObscurePassword = true;
    bool isObscureConfirm = true;
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => ShadDialog(
          title: const Text('Reset Password'),
          description: const Text('Masukkan token reset dan password baru.'),
          // Tambahkan jarak antara form dan tombol dengan Column pembungkus
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadForm(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShadInputFormField(
                      id: 'token',
                      initialValue: token,
                      label: const Text('Token Reset'),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      id: 'password',
                      controller: passwordController,
                      label: const Text('Password Baru'),
                      placeholder: const Text('Masukkan password baru'),
                      obscureText: isObscurePassword,
                      leading: const Icon(Icons.lock_outline),
                      trailing: ShadButton(
                        width: 24,
                        height: 24,
                        padding: EdgeInsets.zero,
                        decoration: const ShadDecoration(),
                        child: Icon(
                          isObscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 16,
                        ),
                        onPressed: () => setState(
                          () => isObscurePassword = !isObscurePassword,
                        ),
                      ),
                      validator: (v) {
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      id: 'confirm_password',
                      controller: confirmController,
                      label: const Text('Konfirmasi Password'),
                      placeholder: const Text('Konfirmasi password baru'),
                      obscureText: isObscureConfirm,
                      leading: const Icon(Icons.lock_outline),
                      trailing: ShadButton(
                        width: 24,
                        height: 24,
                        padding: EdgeInsets.zero,
                        decoration: const ShadDecoration(),
                        child: Icon(
                          isObscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 16,
                        ),
                        onPressed: () => setState(
                          () => isObscureConfirm = !isObscureConfirm,
                        ),
                      ),
                      validator: (v) {
                        if (v != passwordController.text)
                          return 'Password tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Jarak antara form dan tombol
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadButton.outline(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                  const SizedBox(width: 12),
                  ShadButton(
                    child: isLoading
                        ? const AppLoadingWidget(
                            message: 'Memproses...',
                            type: LoadingType.button,
                          )
                        : const Text('Reset Password'),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (formKey.currentState?.saveAndValidate() ??
                                false) {
                              setState(() => isLoading = true);
                              _logger.i('LoginPage: Attempting password reset');
                              final result = await authC.resetPassword(
                                email,
                                token,
                                passwordController.text,
                                confirmController.text,
                              );
                              setState(() => isLoading = false);
                              if (result != null && result['success'] == true) {
                                _logger.i(
                                  'LoginPage: Password reset successful',
                                );
                                Navigator.of(dialogContext).pop();
                                ShadToaster.of(context).show(
                                  ShadToast(
                                    title: const Text('Berhasil'),
                                    description: const Text(
                                      'Password telah direset',
                                    ),
                                  ),
                                );
                              } else {
                                _logger.w(
                                  'LoginPage: Password reset failed: ${result?['message'] ?? 'Unknown error'}',
                                );
                                ShadToaster.of(context).show(
                                  ShadToast.destructive(
                                    title: const Text('Error'),
                                    description: Text(
                                      result?['message'] ??
                                          'Gagal reset password',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
