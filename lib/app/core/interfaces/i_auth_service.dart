// Auth service interface
abstract class IAuthService {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  );
  Future<Map<String, dynamic>> biometricLogin(
    String email,
    String fingerprintId,
  );
  Future<Map<String, dynamic>> activateFingerprint(String fingerprintId);
  Future<Map<String, dynamic>?> getUserInfo();
  Future<List<Map<String, dynamic>>?> getTransactionTypes();
  Future<List<Map<String, dynamic>>?> getCategories();
  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
    String confirmation,
  );
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    dynamic photo,
  });
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String token,
    String password,
    String confirmation,
  );
  Future<String?> getToken();
  Future<void> logout();
  Future<bool> isTokenValid();
}
