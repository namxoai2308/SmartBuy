part of 'auth_cubit.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthSuccess extends AuthState {
  final UserModel user;
  const AuthSuccess(this.user);
  @override List<Object?> get props => [user];
}

final class AuthFailed extends AuthState {
  final String error;
  const AuthFailed(this.error);

  @override
  List<Object?> get props => [error];
}

final class ToggleFormType extends AuthState {
  final AuthFormType authFormType;
  const ToggleFormType(this.authFormType);

  @override
  List<Object?> get props => [authFormType];
}

final class AuthSignUpSuccess extends AuthState {
  const AuthSignUpSuccess();
}
