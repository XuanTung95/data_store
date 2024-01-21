
part of 'data_store.dart';

class LoadResultBase<E> {
  final E? error;
  final bool isSkipped;
  final bool isSuccess;

  const LoadResultBase({
    this.error,
    this.isSkipped = false,
    this.isSuccess = true,
  });
}

class LoadResult<T, E> extends LoadResultBase<E> {
  final T? data;

  const LoadResult({
    E? error,
    this.data,
    bool isSkipped = false,
    bool isSuccess = true,
  }) : super(
    error: error,
    isSkipped: isSkipped,
    isSuccess: isSuccess,
  );
}

class LoadResultPageBase<T, R, E> extends LoadResultBase<E> {
  final List<T>? data;
  final R? response;

  const LoadResultPageBase({
    E? error,
    this.response,
    this.data,
    bool isSkipped = false,
    bool isSuccess = true,
  }) : super(
    error: error,
    isSkipped: isSkipped,
    isSuccess: isSuccess,
  );
}

class LoadResultPage<T, E> extends LoadResultBase<E> {
  final List<T>? data;
  final List<T>? response;

  const LoadResultPage({
    E? error,
    this.data,
    this.response,
    bool isSkipped = false,
    bool isSuccess = true,
  }) : super(
    error: error,
    isSkipped: isSkipped,
    isSuccess: isSuccess,
  );
}

enum LoadState {
  loading,
  success,
  error,
}
