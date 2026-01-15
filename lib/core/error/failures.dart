import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

//Local DAtabase Failure

class LocalDatabaseFailure extends Failure {
  const LocalDatabaseFailure({
    String message = 'Local database operation failed',
  }) : super(message);
}

//API Failure with status code

class ApiFailure extends Failure {
  final int? statusCode;

  const ApiFailure({required String message, this.statusCode}) : super(message);

  @override
  List<Object?> get props => [message, statusCode];
}

//Network Failure

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network connection failed'})
    : super(message);
}
