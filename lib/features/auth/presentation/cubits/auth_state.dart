import '../../data/models/user_model.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AuthAuthenticated &&
              runtimeType == other.runtimeType &&
              user == other.user;

  @override
  int get hashCode => user.hashCode;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthAccountDisabled extends AuthState {
  final String message;
  const AuthAccountDisabled(this.message);
}

class AuthUsersLoaded extends AuthState {
  final List<UserModel> users;
  const AuthUsersLoaded(this.users);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AuthUsersLoaded &&
              runtimeType == other.runtimeType &&
              users == other.users;

  @override
  int get hashCode => users.hashCode;
}

class AuthUserUpdated extends AuthState {
  final UserModel user;
  const AuthUserUpdated(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AuthUserUpdated &&
              runtimeType == other.runtimeType &&
              user == other.user;

  @override
  int get hashCode => user.hashCode;
}

class AuthError extends AuthState {
  final String message;
  final StackTrace? stackTrace;
  const AuthError(this.message, [this.stackTrace]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AuthError &&
              runtimeType == other.runtimeType &&
              message == other.message &&
              stackTrace == other.stackTrace;

  @override
  int get hashCode => message.hashCode ^ stackTrace.hashCode;
}