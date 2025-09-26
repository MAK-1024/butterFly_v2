abstract class UserRoleState {}

class UserRoleInitial extends UserRoleState {}

class UserRoleLoading extends UserRoleState {}

class UserRoleLoaded extends UserRoleState {
  final String role;

  UserRoleLoaded(this.role);
}

class UserRoleError extends UserRoleState {
  final String message;

  UserRoleError(this.message);
}
