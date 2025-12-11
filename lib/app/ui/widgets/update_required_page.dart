import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/global_update_checker.dart';

/// Base widget that forces update check on every page
class UpdateRequiredPage extends StatefulWidget {
  final Widget child;
  final bool forceUpdateOnPageEnter;

  const UpdateRequiredPage({
    super.key,
    required this.child,
    this.forceUpdateOnPageEnter = true,
  });

  @override
  State<UpdateRequiredPage> createState() => _UpdateRequiredPageState();
}

class _UpdateRequiredPageState extends State<UpdateRequiredPage> {
  bool _hasCheckedForUpdate = false;

  @override
  void initState() {
    super.initState();
    _performUpdateCheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for updates every time page becomes visible
    if (widget.forceUpdateOnPageEnter && !_hasCheckedForUpdate) {
      _performUpdateCheck();
    }
  }

  Future<void> _performUpdateCheck() async {
    if (!widget.forceUpdateOnPageEnter) return;

    try {
      await GlobalUpdateChecker.checkOnPageEnter();
      _hasCheckedForUpdate = true;
    } catch (e) {
      // Error handling is done in GlobalUpdateChecker
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mixin for controllers that require forced update checks
mixin UpdateRequiredMixin on GetxController {
  bool _hasPerformedUpdateCheck = false;

  /// Check for updates when controller initializes
  void checkForUpdatesOnInit() {
    if (!_hasPerformedUpdateCheck) {
      _hasPerformedUpdateCheck = true;
      GlobalUpdateChecker.checkOnPageEnter();
    }
  }

  /// Force immediate update check
  void forceUpdateCheck() {
    GlobalUpdateChecker.forceImmediateUpdate();
  }
}
