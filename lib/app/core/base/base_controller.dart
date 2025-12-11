// Enhanced base controller class with unified state management
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../exceptions/app_exception.dart';
import '../utils/error_handler.dart';

/// Unified state class for all controllers
class ControllerState<T> {
  final T? data;
  final bool isLoading;
  final String? error;
  final bool hasData;

  const ControllerState({
    this.data,
    this.isLoading = false,
    this.error,
    this.hasData = false,
  });

  ControllerState<T> copyWith({
    T? data,
    bool? isLoading,
    String? error,
    bool? hasData,
  }) {
    return ControllerState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasData: hasData ?? this.hasData,
    );
  }

  /// Check if state has error
  bool get hasError => error != null && error!.isNotEmpty;

  /// Check if state is in loading state
  bool get isInLoading => isLoading;

  /// Check if state has valid data
  bool get hasValidData => hasData && data != null;

  @override
  String toString() {
    return 'ControllerState(data: $data, isLoading: $isLoading, error: $error, hasData: $hasData)';
  }
}

/// Enhanced base controller with proper state management
abstract class BaseController<Type> extends GetxController {
  final Logger _logger = Logger();
  late final Rx<ControllerState<Type>> _state;

  BaseController() {
    _state = Rx(ControllerState<Type>());
  }

  /// Get current state
  ControllerState<Type> get state => _state.value;

  /// Get reactive state for Rx bindings
  Rx<ControllerState<Type>> get stateRx => _state;

  /// Legacy properties for backward compatibility
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.error;
  bool get hasData => state.hasData;

  /// Set loading state
  void setLoading() {
    _state.value =
        _state.value.copyWith(isLoading: true, error: null)
            as ControllerState<Type>;
  }

  /// Set data state
  void setData(Type data) {
    _state.value =
        _state.value.copyWith(
              data: data,
              isLoading: false,
              hasData: true,
              error: null,
            )
            as ControllerState<Type>;
  }

  /// Set error state
  void setError(String error) {
    _state.value =
        _state.value.copyWith(error: error, isLoading: false)
            as ControllerState<Type>;
  }

  /// Clear error
  void clearError() {
    _state.value = _state.value.copyWith(error: null) as ControllerState<Type>;
  }

  /// Set empty state (no data, no loading, no error)
  void setEmpty() {
    _state.value = ControllerState<Type>(
      isLoading: false,
      hasData: false,
      error: null,
    );
  }

  /// Generic method to handle async operations
  Future<Type?> executeAsync<T extends Type>(
    Future<T> Function() operation, {
    bool setLoadingState = true,
    String? customErrorMessage,
  }) async {
    try {
      if (setLoadingState) {
        setLoading();
      }

      final result = await operation();

      if (result != null) {
        setData(result);
      } else {
        // Handle null result
        setEmpty();
      }

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Async operation failed in ${runtimeType}',
        error: e,
        stackTrace: stackTrace,
      );

      final errorMessage = customErrorMessage ?? ErrorHandler.handle(e);
      setError(errorMessage);

      return null;
    }
  }

  /// Execute operation that doesn't return data
  Future<bool> executeVoidAsync(
    Future<void> Function() operation, {
    bool setLoadingState = true,
    String? customErrorMessage,
  }) async {
    try {
      if (setLoadingState) {
        setLoading();
      }

      await operation();

      // For void operations, just clear loading state
      _state.value =
          _state.value.copyWith(isLoading: false) as ControllerState<Type>;

      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'Void async operation failed in ${runtimeType}',
        error: e,
        stackTrace: stackTrace,
      );

      final errorMessage = customErrorMessage ?? ErrorHandler.handle(e);
      setError(errorMessage);

      return false;
    }
  }

  /// Handle specific exception types
  void handleAppException(AppException exception) {
    final errorMessage = ErrorHandler.handle(exception);
    setError(errorMessage);
  }

  /// Check if current state is valid for operations
  bool get canPerformOperation => !state.isLoading && !state.hasError;

  /// Get formatted error message for display
  String get formattedErrorMessage {
    if (!state.hasError) return '';
    return state.error!;
  }

  /// Legacy methods for backward compatibility
  @deprecated
  void setLegacyLoading(bool value) {
    if (value) {
      setLoading();
    } else {
      _state.value =
          _state.value.copyWith(isLoading: false) as ControllerState<Type>;
    }
  }

  @deprecated
  void setLegacyError(String message) {
    setError(message);
  }

  @deprecated
  void clearLegacyError() {
    clearError();
  }

  @override
  void onClose() {
    // Close the state stream when controller is disposed
    _state.close();
    super.onClose();
  }
}

/// Extension for convenient state checks
extension ControllerStateExtensions<T> on ControllerState<T> {
  /// Check if state represents a success condition
  bool get isSuccess => hasData && !isLoading && !hasError;

  /// Check if state represents an error condition
  bool get isError => hasError && !isLoading;

  /// Check if state is in initial/empty condition
  bool get isEmpty => !hasData && !isLoading && !hasError;

  /// Get data with type safety
  T? get safeData => hasValidData ? data : null;

  /// Get loading progress as percentage (0.0 to 1.0)
  double get loadingProgress => isLoading ? 0.5 : (hasData ? 1.0 : 0.0);
}

/// Extension for enhanced BaseController functionality
extension BaseControllerExtensions<Type> on BaseController<Type> {
  /// Check if controller is ready for user interactions
  bool get isReadyForInteraction => canPerformOperation && state.hasValidData;

  /// Get data with fallback
  Type getDataOrFallback(Type fallback) {
    return state.safeData ?? fallback;
  }

  /// Perform operation only if controller is ready
  Future<Type?> safeExecute<T extends Type>(
    Future<T> Function() operation,
  ) async {
    if (!canPerformOperation) {
      _logger.w('Operation skipped: controller not ready (${runtimeType})');
      return null;
    }

    return await executeAsync<T>(operation);
  }

  /// Reset controller to initial state
  void reset() {
    setEmpty();
    _logger.i('Controller ${runtimeType} reset to initial state');
  }
}
