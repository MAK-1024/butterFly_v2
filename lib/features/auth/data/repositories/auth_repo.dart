import '../datasources/auth_data_source.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthDataSource _authDataSource;

  AuthRepository(this._authDataSource);

  Future<UserModel?> signIn(String email, String password) async {
    final user = await _authDataSource.signInWithEmailPassword(email, password);
    if (user != null) {
      return await _authDataSource.fetchUserDetails(user.uid);
    }
    return null;
  }
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }
}
