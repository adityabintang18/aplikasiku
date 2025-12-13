import 'dart:io';
import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aplikasiku/app/controllers/profile_controller.dart';
import 'package:aplikasiku/app/controllers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/loading_widget.dart';
import '../../data/services/version_service.dart';
// import '../widgets/error_widget.dart';
// import '../widgets/error_boundary.dart';
// import '../../core/errors/app_exception.dart';

class ProfilePage extends GetView<ProfileController> {
  final logger = Logger();
  final VersionService _versionService = VersionService();

  AuthController get authController => Get.find<AuthController>();

  // Shadcn-inspired color palette
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color accent = Color(0xFFF1F5F9);
  static const Color primary = Color(0xFF0F172A);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  String? _appVersion; // Store version
  bool _hasLoadedVersion = false;

  @override
  Widget build(BuildContext context) {
    // Call onPageEnter when page is built (refreshes data every time page is entered)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageEnter();
    });

    // Load version if not loaded yet
    if (!_hasLoadedVersion) {
      _hasLoadedVersion = true;
      _versionService.getCurrentVersion().then((value) {
        _appVersion = value;
        if (context.mounted) {
          // Update UI
          // ignore: invalid_use_of_protected_member
          (context as Element).markNeedsBuild();
        }
      });
    }

    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingWidget(
            message: 'Loading profile...',
            type: LoadingType.profilePage,
          );
        }

        final userInfo = controller.userInfo;
        final userName = userInfo['name'] ?? "User";
        final userEmail = userInfo['email'] ?? "user@example.com";
        // final firstName = userName.split(' ').first;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 20),
                // User Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: background,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: border,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: border,
                          backgroundImage: userInfo['photo_url'] != null
                              ? NetworkImage(userInfo['photo_url'])
                              : const AssetImage('assets/avatar.png')
                                  as ImageProvider,
                          child: userInfo['photo_url'] == null
                              ? Text(
                                  _getInitials(userName),
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: foreground,
                              ),
                            ),
                            Text(
                              userEmail,
                              style: TextStyle(color: muted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEditProfileDialog(context),
                        icon: Icon(Icons.edit_outlined, color: muted),
                        style: IconButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Settings Sections
                // _buildSettingsSection('ACCOUNT', [
                //   _buildMenuItem(
                //     icon: Icons.settings,
                //     title: "Account Settings",
                //     subtitle: "Manage your account",
                //     iconBgColor: primary.withOpacity(0.1),
                //     iconColor: primary,
                //     onTap: () {},
                //   ),
                //   _buildMenuItem(
                //     icon: Icons.language,
                //     title: "Currency Preference",
                //     subtitle: "IDR - Indonesian Rupiah",
                //     iconBgColor: const Color(0xFF06B6D4).withOpacity(0.1),
                //     iconColor: const Color(0xFF06B6D4),
                //     onTap: () {},
                //   ),
                //   _buildNotificationItem(),
                // ]),
                // const SizedBox(height: 16),
                // _buildSettingsSection('APPEARANCE', [
                //   _buildMenuItem(
                //     icon: Icons.palette,
                //     title: "Theme",
                //     subtitle: "Light mode",
                //     iconBgColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                //     iconColor: const Color(0xFF8B5CF6),
                //     onTap: () {},
                //   ),
                // ]),
                // const SizedBox(height: 16),
                _buildSettingsSection('SECURITY', [
                  _buildMenuItem(
                    icon: Icons.lock,
                    title: "Change Password",
                    subtitle: "Update your password",
                    iconBgColor: accent,
                    iconColor: foreground,
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  // _buildMenuItem(
                  //   icon: Icons.shield,
                  //   title: "Privacy Settings",
                  //   subtitle: "Manage your privacy",
                  //   iconBgColor: accent,
                  //   iconColor: foreground,
                  //   onTap: () {},
                  // ),
                  _buildBiometricItem(context),
                ]),
                const SizedBox(height: 16),
                _buildSettingsSection('OTHER', [
                  _buildMenuItem(
                    icon: Icons.help,
                    title: "Help & Support",
                    subtitle: "Get help with Aplikasiku",
                    iconBgColor: accent,
                    iconColor: foreground,
                    onTap: () => _openWhatsApp(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.info,
                    title: "About",
                    subtitle: "Version ${_appVersion ?? '...'}",
                    iconBgColor: accent,
                    iconColor: foreground,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 24),
                // Logout Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: () => authController.logout(),
                    icon: Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [entry.value, if (!isLast) _buildDivider()],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color ?? foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fingerprint,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Login',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Enable fingerprint login',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Obx(() {
            final isEnabled = authController.isBiometricEnabled.value;
            return ShadSwitch(
              value: isEnabled,
              onChanged: (value) async {
                final success = await authController.toggleBiometricSetting(
                  value,
                );
                if (success && value) {
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        title: const Text('Berhasil'),
                        description: const Text(
                          'Login biometrik telah diaktifkan',
                        ),
                      ),
                    );
                  }
                } else if (!success && value) {
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: const Text('Error'),
                        description: const Text('Validasi biometrik gagal'),
                      ),
                    );
                  }
                } else if (!value) {
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        title: const Text('Berhasil'),
                        description: const Text(
                          'Login biometrik telah dinonaktifkan',
                        ),
                      ),
                    );
                  }
                }
                // The reactive variable is already updated by the controller methods
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: border,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<ShadFormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isObscureOld = true;
    bool isObscureNew = true;
    bool isObscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => ShadDialog(
          title: const Text('Ubah Password'),
          description: const Text(
            'Masukkan password lama dan password baru Anda.',
          ),
          child: ShadForm(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInputFormField(
                  id: 'old_password',
                  controller: oldPasswordController,
                  label: const Text('Password Lama'),
                  placeholder: const Text('Masukkan password lama'),
                  obscureText: isObscureOld,
                  leading: const Icon(Icons.lock_outline),
                  trailing: ShadButton(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.zero,
                    decoration: const ShadDecoration(),
                    child: Icon(
                      isObscureOld ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                    ),
                    onPressed: () =>
                        setState(() => isObscureOld = !isObscureOld),
                  ),
                  validator: (v) {
                    if (v.isEmpty) return 'Password lama wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ShadInputFormField(
                  id: 'new_password',
                  controller: newPasswordController,
                  label: const Text('Password Baru'),
                  placeholder: const Text('Masukkan password baru'),
                  obscureText: isObscureNew,
                  leading: const Icon(Icons.lock_outline),
                  trailing: ShadButton(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.zero,
                    decoration: const ShadDecoration(),
                    child: Icon(
                      isObscureNew ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                    ),
                    onPressed: () =>
                        setState(() => isObscureNew = !isObscureNew),
                  ),
                  validator: (v) {
                    if (v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ShadInputFormField(
                  id: 'confirm_password',
                  controller: confirmPasswordController,
                  label: const Text('Konfirmasi Password Baru'),
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
                    onPressed: () =>
                        setState(() => isObscureConfirm = !isObscureConfirm),
                  ),
                  validator: (v) {
                    if (v != newPasswordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24), // Jarak antara form dan tombol
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
                  : const Text('Ubah Password'),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState?.saveAndValidate() ?? false) {
                        setState(() => isLoading = true);

                        final result = await controller.changePassword(
                          oldPasswordController.text,
                          newPasswordController.text,
                          confirmPasswordController.text,
                        );

                        setState(() => isLoading = false);

                        if (result != null && result['success'] == true) {
                          Navigator.of(dialogContext).pop();
                          ShadToaster.of(context).show(
                            ShadToast(
                              title: const Text('Berhasil'),
                              description: Text(
                                result['message'] ?? 'Password berhasil diubah',
                              ),
                            ),
                          );
                        } else {
                          ShadToaster.of(context).show(
                            ShadToast.destructive(
                              title: const Text('Error'),
                              description: Text(
                                result?['message'] ?? 'Gagal mengubah password',
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

  void _showEditProfileDialog(BuildContext context) {
    final formKey = GlobalKey<ShadFormState>();
    final nameController = TextEditingController(
      text: controller.userInfo['name'] ?? '',
    );
    final emailController = TextEditingController(
      text: controller.userInfo['email'] ?? '',
    );
    final imagePicker = ImagePicker();
    XFile? selectedImage;
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => ShadDialog(
          title: const Text('Ubah Profile'),
          description: const Text('Perbarui nama dan email Anda.'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadForm(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShadInputFormField(
                      id: 'name',
                      controller: nameController,
                      label: const Text('Nama'),
                      placeholder: const Text('Masukkan nama'),
                      validator: (v) {
                        if (v.isEmpty) return 'Nama wajib diisi';
                        if (v.length > 255) return 'Nama maksimal 255 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadInputFormField(
                      id: 'email',
                      controller: emailController,
                      label: const Text('Email'),
                      placeholder: const Text('Masukkan email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                          return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await imagePicker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            setState(() => selectedImage = picked);
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: selectedImage != null
                              ? FileImage(File(selectedImage!.path))
                              : (controller.userInfo['photo_url'] != null
                                  ? NetworkImage(
                                      controller.userInfo['photo_url'],
                                    )
                                  : const AssetImage('assets/avatar.png')
                                      as ImageProvider),
                          child: selectedImage == null &&
                                  controller.userInfo['photo_url'] == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 30,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      'Tap avatar to change photo',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Jarakan antara form dan button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadButton.outline(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                  const SizedBox(width: 12),
                  ShadButton(
                    child: isLoading
                        ? const AppLoadingWidget(
                            message: 'Memproses...',
                            type: LoadingType.button,
                          )
                        : const Text('Update Profile'),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (formKey.currentState?.saveAndValidate() ??
                                false) {
                              setState(() => isLoading = true);
                              final result = await controller.updateProfile(
                                {
                                  'name': nameController.text.trim(),
                                  'email': emailController.text.trim(),
                                },
                                photo: selectedImage != null
                                    ? File(selectedImage!.path)
                                    : null,
                              );
                              setState(() => isLoading = false);
                              if (result != null && result['success'] == true) {
                                Navigator.of(dialogContext).pop();
                                ShadToaster.of(context).show(
                                  ShadToast(
                                    title: const Text('Success'),
                                    description: const Text(
                                      'Profile updated successfully',
                                    ),
                                  ),
                                );
                              } else {
                                final errorMessage = _formatErrorMessage(
                                  result,
                                );
                                ShadToaster.of(context).show(
                                  ShadToast.destructive(
                                    title: const Text('Error'),
                                    description: Text(errorMessage),
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

  void _openWhatsApp(BuildContext context) async {
    const phone = '6282290639529';
    final url = 'https://wa.me/$phone';
    final uri = Uri.parse(url);

    try {
      // Coba langsung launch WhatsApp tanpa canLaunchUrl (menghindari PlatformException)
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Jika gagal, tampilkan notifikasi error
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error'),
          description: Text(
            'Tidak dapat membuka WhatsApp. Pastikan WhatsApp terinstall dan tersedia di perangkat Anda.',
          ),
        ),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return parts[0].substring(0, 1).toUpperCase();
    }
  }

  String _formatErrorMessage(Map<String, dynamic>? result) {
    if (result == null) return 'Unknown error';
    final buffer = StringBuffer();
    final message = result['message'];
    if (message != null) {
      buffer.writeln(message);
    }
    final errors = result['errors'] as Map<String, dynamic>?;
    if (errors != null) {
      for (final field in errors.keys) {
        final fieldErrors = errors[field] as List<dynamic>?;
        if (fieldErrors != null) {
          for (final error in fieldErrors) {
            buffer.writeln('$field: $error');
          }
        }
      }
    }
    final details = result['details'] as List<dynamic>?;
    if (details != null) {
      for (final detail in details) {
        buffer.writeln(detail);
      }
    }
    return buffer.toString().trim();
  }
}
