import 'package:get/get.dart';
import 'package:aplikasiku/app/routes/app_routes.dart';

class UpdateController extends GetxController {
  var showUpdatePage = false.obs;

  void triggerUpdatePage() {
    showUpdatePage.value = true;
    print('UpdateController: Navigating to /update-required using GoRouter');
    router.go('/update-required');
  }

  void resetUpdatePage() {
    showUpdatePage.value = false;
  }
}
