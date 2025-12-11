// Unit tests for LoginUseCase
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

// Test file imports - using relative paths from test directory
import '../../../../lib/app/domain/usecases/auth/login_usecase.dart';
import '../../../../lib/app/core/entities/login_params.dart';
import '../../../../lib/app/core/entities/user_entity.dart';
import '../../../../lib/app/core/entities/auth_result.dart';
import '../../../../lib/app/core/exceptions/app_exception.dart';

// Mock repository import
import '../../../../test/mocks/mock_auth_repository.dart';

void main() {
  group('LoginUseCase', () {
    late LoginUseCase loginUseCase;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      loginUseCase = LoginUseCase(
        authRepository: mockAuthRepository,
        logger: Logger(), // Use actual logger for tests
      );
    });

    test('should return success when login is successful', () async {
      // Arrange
      final loginParams = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );

      final expectedUser = UserEntity.withRequiredFields(
        id: 1,
        name: 'Test User',
        email: 'test@example.com',
      );

      mockAuthRepository.setupSuccessfulLogin(user: expectedUser);

      // Act
      final result = await loginUseCase.execute(loginParams);

      // Assert
      expect(result.isSuccess, true);
      expect(result.user, equals(expectedUser));
      expect(result.message, equals('Login successful'));
      expect(mockAuthRepository.wasCalled('login'), true);
      expect(mockAuthRepository.getCallCount('login'), 1);
    });

    test('should return failure when login parameters are invalid', () async {
      // Arrange
      final invalidParams = LoginParams(
        email: '', // Invalid empty email
        password: '123', // Invalid short password
      );

      // Act
      final result = await loginUseCase.execute(invalidParams);

      // Assert
      expect(result.isSuccess, false);
      expect(result.message, contains('Invalid input'));
      expect(result.message, contains('Email is required'));
      expect(
        result.message,
        contains('Password must be at least 6 characters'),
      );
      expect(
        mockAuthRepository.wasCalled('login'),
        false,
      ); // Should not call repository
    });

    test('should return failure when repository returns failure', () async {
      // Arrange
      final loginParams = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );

      mockAuthRepository.setupFailedLogin(message: 'Invalid credentials');

      // Act
      final result = await loginUseCase.execute(loginParams);

      // Assert
      expect(result.isSuccess, false);
      expect(result.message, equals('Invalid credentials'));
      expect(mockAuthRepository.wasCalled('login'), true);
    });

    test('should handle NetworkException properly', () async {
      // Arrange
      final loginParams = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );

      mockAuthRepository.setupThrowException(
        NetworkException('No internet connection'),
      );

      // Act
      final result = await loginUseCase.execute(loginParams);

      // Assert
      expect(result.isSuccess, false);
      expect(result.message, contains('Network error'));
    });

    test('should not call repository when parameters are invalid', () async {
      // Arrange
      final invalidParams = LoginParams(email: '', password: '');

      // Clear call history
      mockAuthRepository.clearCallHistory();

      // Act
      final result = await loginUseCase.execute(invalidParams);

      // Assert
      expect(result.isSuccess, false);
      expect(mockAuthRepository.wasCalled('login'), false);
      expect(mockAuthRepository.getCallCount('login'), 0);
    });

    tearDown(() {
      mockAuthRepository.clearCallHistory();
    });
  });
}
