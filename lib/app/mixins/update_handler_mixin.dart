import 'package:get/get.dart';
import 'package:aplikasiku/app/controllers/update_controller.dart';

mixin UpdateHandlerMixin on GetxController {
  void handleUpdateException() {
    print('UpdateHandlerMixin: handleUpdateException called');
    _showUpdatePage();
  }

  void _showUpdatePage() {
    print('UpdateHandlerMixin: Triggering update controller');
    final updateController = Get.find<UpdateController>();
    updateController.triggerUpdatePage();
  }
}
