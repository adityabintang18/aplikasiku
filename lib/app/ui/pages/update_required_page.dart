import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aplikasiku/app/controllers/update_controller.dart';
import 'package:get/get.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/error_boundary.dart';
import '../../core/errors/app_exception.dart';

class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Update Required',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'A new version of the app is available. Please update to continue using the app.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  const url =
                      'https://play.google.com/store/apps/details?id=com.aplikasiku';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Update Now'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Reset update page state and go back
                  final updateController = Get.find<UpdateController>();
                  updateController.resetUpdatePage();
                  GoRouter.of(context).go('/');
                },
                child: const Text('Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
