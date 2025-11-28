sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Pending<T> extends Result<T> {
  final String? message;
  const Pending([this.message]);
}

final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message,[this.error]);
}

extension ResultExtensions<T> on Result<T> {
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
    R Function(String? message)? pending,
}) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else if (this is Failure<T>) {
      final f = this as Failure<T>;
      return failure(f.message,f.error);
    } else if (this is Pending<T>) {
      if (pending != null) {
        return pending((this as Pending<T>).message);
      }
      throw StateError('Pending state must be handled');
    }
    throw StateError('Unknown Result type: $runtimeType');
  }
}