abstract class Failure {
  Failure({required this.message});

  final String message;
}

class UnknownFailure extends Failure {
  UnknownFailure({super.message = 'Error desconocido'});
}
