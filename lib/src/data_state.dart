
part of 'data_store.dart';

class DataState<T, E> {
  DataState({
    required this.loadState,
    this.data,
    this.error,
  });

  final T? data;
  final LoadState loadState;
  final E? error;
  bool get isLoading => loadState == LoadState.loading;

  DataState<T, E> copyWith({
    T? data,
    LoadState? loadState,
    E? error,
  }) {
    return DataState<T, E>(
      data: data ?? this.data,
      loadState: loadState ?? this.loadState,
      error: error ?? this.error,
    );
  }
}
