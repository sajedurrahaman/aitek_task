import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.login,
    required this.peanutToken,
    required this.partnerToken,
  });

  final int login;
  final String peanutToken;
  final String partnerToken;

  @override
  List<Object?> get props => [login, peanutToken, partnerToken];
}
