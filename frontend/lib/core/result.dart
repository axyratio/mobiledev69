/// Result type for the data layer: every repository call returns
/// [Ok]/[Err] instead of throwing, so ViewModels handle failures explicitly
/// rather than via try/catch (Code Quality checklist: "Result Pattern
/// จัดการข้อผิดพลาดใน Data Layer").
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(String message) = Err<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.message);
  final String message;
}
