import 'package:get/get.dart';
import 'package:aplikasiku/app/data/services/financial_service.dart';

class FinansialController extends GetxController {
  final FinansialService _service = FinansialService();

  var summary = {}.obs;
  var transaksiList = [].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    fetchSummary();
    fetchTransaksi();
    super.onInit();
  }

  Future<void> fetchSummary() async {
    try {
      isLoading(true);
      summary.value = await _service.getSummary();
    } catch (e) {
      print("Error summary: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTransaksi() async {
    try {
      isLoading(true);
      transaksiList.value = await _service.getAll();
    } catch (e) {
      print("Error transaksi: $e");
    } finally {
      isLoading(false);
    }
  }
}
