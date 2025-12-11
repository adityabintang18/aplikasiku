import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:aplikasiku/app/controllers/transaction_controller.dart';
import 'package:aplikasiku/app/controllers/home_controller.dart';
import 'package:aplikasiku/app/data/models/financial_model.dart';
import 'package:aplikasiku/app/utils/helpers.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final TransactionController _transactionController =
      Get.find<TransactionController>();
  final HomeController _homeController = Get.find<HomeController>();
  String _type = "expense";
  String? _selectedCategory;
  int? _selectedCategoryId;
  int? _selectedTransactionType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final formKey = GlobalKey<ShadFormState>();
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default transaction type from API data
    if (_homeController.transactionTypes.isNotEmpty) {
      _selectedTransactionType = _homeController.transactionTypes.first['id'];
    }

    // Set default category from API data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_homeController.categories.isNotEmpty) {
        final filteredCategories = _getFilteredCategories();
        if (filteredCategories.isNotEmpty) {
          setState(() {
            _selectedCategoryId = filteredCategories.first['id'] as int;
            _selectedCategory = filteredCategories.first['nama'] ??
                filteredCategories.first['name'] ??
                '';
          });
        }
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      } else {
        // User canceled image picker
        print('Image picker was canceled by user');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: ShadDialog.alert(
              title: const Text('Error'),
              description: Text(
                'Failed to pick image.\nError: ${e.runtimeType}: ${e.toString()}',
              ),
              actions: [
                ShadButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _submit() async {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final values = formKey.currentState!.value;

        final amount =
            parseFormattedAmount(values['amount']?.toString() ?? '0');
        final title = _noteController.text.isEmpty
            ? _selectedCategory ?? 'Transaction'
            : _noteController.text;

        final newTransaction = FinansialModel(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          title: title,
          category: _selectedCategoryId ?? 1,
          isIncome: _type == "income",
          date: _selectedDate.toIso8601String().split('T').first,
          amount: amount,
          description: _noteController.text,
          namaKategori: _selectedCategory ?? 'Transaction',
          namaJenisKategori: _selectedTransactionType?.toString() ?? "personal",
        );

        await _transactionController.addTransaction(
          newTransaction,
          photo: _selectedImage,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            builder: (context) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: ShadDialog.alert(
                title: const Text('Success'),
                description: const Text('Transaction added successfully'),
                actions: [
                  ShadButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Close modal
                    },
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text('Error'),
              description: Text('Failed to add transaction: ${e.toString()}'),
            ),
          );
        }
      } finally {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: const Text(
              'Please fill all required fields correctly',
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredCategories() {
    return _homeController.categories.where((category) {
      final deskripsi = category['deskripsi']?.toString().toLowerCase() ?? '';
      if (_type == 'income') {
        return deskripsi.contains('pemasukan') || deskripsi.contains('income');
      } else {
        return deskripsi.contains('pengeluaran') ||
            deskripsi.contains('expense');
      }
    }).toList();
  }

  IconData _getIconFromApi(String iconString) {
    final iconMap = {
      "money": Icons.attach_money,
      "car": Icons.directions_car,
      "restaurant": Icons.restaurant,
      "shopping": Icons.shopping_bag,
      "work": Icons.work,
      "default": Icons.category,
    };
    return iconMap[iconString] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ShadForm(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Add Transaction",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).maybePop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = "expense";
                              // Reset category selection when switching type
                              _selectedCategoryId = null;
                              _selectedCategory = null;
                              // Set default category for expense after state update
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final filteredCategories =
                                    _getFilteredCategories();
                                if (filteredCategories.isNotEmpty) {
                                  setState(() {
                                    _selectedCategoryId =
                                        filteredCategories.first['id'] as int;
                                    _selectedCategory =
                                        filteredCategories.first['nama'] ??
                                            filteredCategories.first['name'] ??
                                            '';
                                  });
                                }
                              });
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == "expense"
                                  ? Colors.red.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _type == "expense"
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              "Expense",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _type == "expense"
                                    ? Colors.red
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = "income";
                              // Reset category selection when switching type
                              _selectedCategoryId = null;
                              _selectedCategory = null;
                              // Set default category for income after state update
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final filteredCategories =
                                    _getFilteredCategories();
                                if (filteredCategories.isNotEmpty) {
                                  setState(() {
                                    _selectedCategoryId =
                                        filteredCategories.first['id'] as int;
                                    _selectedCategory =
                                        filteredCategories.first['nama'] ??
                                            filteredCategories.first['name'] ??
                                            '';
                                  });
                                }
                              });
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == "income"
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _type == "income"
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              "Income",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _type == "income"
                                    ? Colors.green
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Transaction Type",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 80, // Fixed height untuk konsistensi
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: _homeController.transactionTypes.length,
                      itemBuilder: (context, index) {
                        final txType = _homeController.transactionTypes[index];
                        final isSelected =
                            _selectedTransactionType == txType["id"];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTransactionType = txType["id"];
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getIconFromApi(
                                      txType["icon"]?.toString() ?? "default",
                                    ),
                                    size: 20,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 2),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: Text(
                                      txType["nama"] ??
                                          txType["name"] ??
                                          "Unknown",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ShadDatePickerFormField(
                    label: const Text(
                      "Date",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onChanged: (DateTime? picked) {
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    validator: (v) {
                      if (v == null) {
                        return 'A date is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  ShadInputFormField(
                    id: 'amount',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      ThousandsFormatter(), // ← This enables auto formatting
                    ],
                    label: const Text(
                      "Amount",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    placeholder: const Text("0"),
                    leading: const Text("Rp "),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Amount is required';
                      }
                      final parsedAmount = parseFormattedAmount(value);
                      if (parsedAmount <= 0) {
                        return 'Please enter a valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  ShadSelectFormField<String>(
                    id: 'category',
                    minWidth: 350,
                    label: const Text(
                      "Category",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initialValue: null,
                    options: _getFilteredCategories()
                        .map(
                          (category) => ShadOption(
                            value: category['id'].toString(),
                            child: Text(
                              category['nama'] ?? category['name'] ?? 'Unknown',
                            ),
                          ),
                        )
                        .toList(),
                    selectedOptionBuilder: (context, value) {
                      if (value == null) {
                        return const Text("Select category");
                      }
                      final selectedCat = _getFilteredCategories().firstWhere(
                        (cat) => cat['id'].toString() == value,
                        orElse: () => {},
                      );
                      return Text(
                        selectedCat['nama'] ?? selectedCat['name'] ?? 'Unknown',
                      );
                    },
                    placeholder: const Text("Select category"),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategoryId = int.parse(value);
                          final selectedCat =
                              _getFilteredCategories().firstWhere(
                            (cat) => cat['id'].toString() == value,
                            orElse: () => {},
                          );
                          _selectedCategory =
                              selectedCat['nama'] ?? selectedCat['name'] ?? '';
                        });
                      }
                    },
                    validator: (v) {
                      if (v == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Upload Image (Optional)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 7),
                  if (_selectedImage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImage!.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ShadButton.outline(
                    onPressed: _pickImage,
                    width: double.infinity,
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          _selectedImage != null
                              ? "Change Image"
                              : "Choose Image",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  ShadInputFormField(
                    id: 'note',
                    controller: _noteController,
                    label: const Text(
                      "Note (Optional)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    placeholder: const Text("Add a note..."),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ShadButton.outline(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          width: double.infinity,
                          height: 45,
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ShadButton(
                          onPressed: _isLoading ? null : _submit,
                          width: double.infinity,
                          height: 45,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text("Add"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
