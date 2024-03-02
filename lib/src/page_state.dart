
part of 'data_store.dart';

class PageState<T, E> {
  PageState({
    required this.data,
    required this.initPage,
    required this.isLastPage,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.loadState,
    this.error,
    this.rawResponse,
  });

  final List<T> data;
  final int initPage;
  final bool isLastPage;
  final int total;
  final int page;
  final int pageSize;
  final LoadState loadState;
  final E? error;
  final dynamic rawResponse;
  bool get isLoading => loadState == LoadState.loading;

  PageState<T, E> copyWith({
    List<T>? data,
    int? initPage,
    bool? isLastPage,
    int? total,
    int? page,
    int? pageSize,
    LoadState? loadState,
    E? error,
    dynamic rawResponse,
  }) {
    return PageState<T, E>(
      data: data ?? this.data,
      initPage: initPage ?? this.initPage,
      isLastPage: isLastPage ?? this.isLastPage,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      loadState: loadState ?? this.loadState,
      error: error ?? this.error,
      rawResponse: rawResponse,
    );
  }

  PageState<T, E> success({
    List<T>? data,
    int? initPage,
    bool? isLastPage,
    int? total,
    int? page,
    int? pageSize,
    LoadState? loadState,
    E? error,
    dynamic rawResponse,
  }) {
    return PageState<T, E>(
      data: data ?? this.data,
      initPage: initPage ?? this.initPage,
      isLastPage: isLastPage ?? this.isLastPage,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      loadState: loadState ?? this.loadState,
      error: error,
      rawResponse: rawResponse,
    );
  }
}