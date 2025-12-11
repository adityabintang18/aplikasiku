import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/loading_widget.dart';
// import '../widgets/error_widget.dart';
// import '../widgets/error_boundary.dart';
// import '../../core/errors/app_exception.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<ShadFormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final authC = Get.find<AuthController>();

  bool _isLoading = false;
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  Future<void> _handleFormSubmit() async {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      print(
        'register validation succeeded with ${formKey.currentState!.value}',
      );
      setState(() => _isLoading = true);

      final values = formKey.currentState!.value;
      final name = values['name']?.toString().trim() ?? '';
      final email = values['email']?.toString().trim() ?? '';
      final password = values['password']?.toString() ?? '';
      final confirmPassword = values['confirmPassword']?.toString() ?? '';

      if (password != confirmPassword) {
        setState(() => _isLoading = false);
        // Password validation is handled by form validator, but we check again here
        return;
      }

      final result = await authC.register(
        name,
        email,
        password,
        confirmPassword,
      );
      setState(() => _isLoading = false);

      if (result != null && result['success'] == true) {
        if (mounted) context.go('/login');
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Berhasil'),
            description: Text(
              result['message']?.toString() ??
                  'Registrasi berhasil! Silakan login.',
            ),
          ),
        );
      } else {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Gagal'),
            description: Text(
              result?['message']?.toString() ?? 'Registrasi gagal. Coba lagi.',
            ),
          ),
        );
      }
    } else {
      print('register validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 20),
                const Text(
                  'Buat Akun Baru',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                ShadInputFormField(
                  id: 'name',
                  controller: _nameController,
                  label: const Text('Nama'),
                  placeholder: const Text('Masukkan nama Anda'),
                  // description: const Text(
                  //   'Email Anda yang digunakan untuk login.',
                  // ),
                  leading: const Icon(Icons.person),
                  validator: (v) {
                    if (v.isEmpty) {
                      return 'Nama tidak boleh kosong.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
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
                    // Regex untuk validasi email yang sederhana.
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(v)) {
                      return 'Email harus valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                ShadInputFormField(
                  id: 'confirmPassword',
                  controller: _confirmPasswordController,
                  obscureText: _isConfirmPasswordObscure,
                  label: const Text('Konfirmasi Kata Sandi'),
                  placeholder: const Text('Masukkan ulang kata sandi'),
                  // description: const Text(
                  //   'Harus sama dengan kata sandi di atas.',
                  // ),
                  leading: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(LucideIcons.lock),
                  ),
                  trailing: ShadButton(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.zero,
                    child: Icon(
                      _isConfirmPasswordObscure
                          ? LucideIcons.eyeOff
                          : LucideIcons.eye,
                    ),
                    onPressed: () {
                      setState(
                        () => _isConfirmPasswordObscure =
                            !_isConfirmPasswordObscure,
                      );
                    },
                  ),
                  validator: (v) {
                    if (v.isEmpty) {
                      return 'Konfirmasi kata sandi tidak boleh kosong.';
                    }
                    final passwordValue =
                        formKey.currentState?.value['password'];
                    if (passwordValue != null &&
                        v != passwordValue.toString()) {
                      return 'Kata sandi tidak cocok.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
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
                          'Daftar',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 10),
                ShadButton.ghost(
                  onPressed: () => context.go('/login'),
                  width: double.infinity,
                  height: 45,
                  child: const Text('Sudah punya akun? Masuk disini'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
