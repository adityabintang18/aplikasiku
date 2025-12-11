import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/financial_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/statistic_controller.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/update_controller.dart';
import '../core/services/error_handler_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Essential services that must be available immediately
    Get.put(ErrorHandlerService());

    // Only put essential controllers that don't immediately load data
    Get.put(FinansialController());
    // HomeController will be put lazily when needed to prevent immediate data loading
    Get.lazyPut(() => HomeController());
    Get.put(ProfileController());
    Get.put(StatisticController());
    Get.put(TransactionController());
    Get.put(UpdateController());
  }
}
