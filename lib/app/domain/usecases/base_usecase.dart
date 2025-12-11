// Base use case interface and result wrapper
import 'package:equatable/equatable.dart';

/// Base result for all use cases
abstract class UseCaseResult extends Equatable {
  const UseCaseResult();

  /// Check if operation was successful
  bool get isSuccess => false;

  /// Get error message if failed
  String? get errorMessage => null;

  /// Get error code if failed
  String? get errorCode => null;

  @override
  List<Object?> get props => [];
}

/// Successful use case result
class UseCaseSuccess<T> extends UseCaseResult {
  final T data;

  const UseCaseSuccess(this.data);

  @override
  bool get isSuccess => true;

  @override
  List<Object?> get props => [data];

  @override
  String toString() => 'UseCaseSuccess($data)';
}

/// Failed use case result
class UseCaseFailure extends UseCaseResult {
  final String message;
  final String? code;
  final dynamic error;

  const UseCaseFailure({required this.message, this.code, this.error});

  @override
  String get errorMessage => message;

  @override
  String? get errorCode => code;

  @override
  List<Object?> get props => [message, code, error];

  @override
  String toString() =>
      'UseCaseFailure(message: $message, code: $code, error: $error)';
}

/// Generic use case interface
abstract class UseCase<T, P> {
  const UseCase();

  /// Execute use case with parameters
  Future<T> execute(P params);

  /// Execute use case with no parameters
  Future<T> call() => execute(null as P);
}

/// Generic use case with no parameters and no return value
abstract class VoidUseCase<P> {
  const VoidUseCase();

  /// Execute use case with parameters
  Future<void> execute(P params);

  /// Execute use case with no parameters
  Future<void> call() => execute(null as P);
}

/// Extension for easy result handling
extension UseCaseResultExtension on UseCaseResult {
  /// Execute callback for success
  T? onSuccess<T>(T Function(Object data) callback) {
    if (this is UseCaseSuccess) {
      return callback((this as UseCaseSuccess).data);
    }
    return null;
  }

  /// Execute callback for failure
  void onFailure(void Function(String message, String? code) callback) {
    if (this is UseCaseFailure) {
      final failure = this as UseCaseFailure;
      callback(failure.message, failure.code);
    }
  }

  /// Fold result into single type
  R fold<R>(
    R Function(String message, String? code) onFailure,
    R Function(Object data) onSuccess,
  ) {
    if (this is UseCaseSuccess) {
      return onSuccess((this as UseCaseSuccess).data);
    } else {
      final failure = this as UseCaseFailure;
      return onFailure(failure.message, failure.code);
    }
  }
}

/// Helper class for creating use case results
class UseCaseResultHelper {
  /// Create success result
  static UseCaseSuccess<T> success<T>(T data) {
    return UseCaseSuccess(data);
  }

  /// Create failure result
  static UseCaseFailure failure(String message, {String? code, dynamic error}) {
    return UseCaseFailure(message: message, code: code, error: error);
  }
}

/// AuthResult wrapper for use case results
class AuthResultWrapper<T> {
  final bool success;
  final T? data;
  final String message;
  final String? errorCode;

  const AuthResultWrapper({
    required this.success,
    this.data,
    required this.message,
    this.errorCode,
  });

  bool get isSuccess => success;
  String? get errorMessage => success ? null : message;
}
