import 'dart:async';
import 'package:future_interceptor/future_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/loading_interceptor.dart';
import 'interceptors/page_response_interceptor.dart';
import 'interceptors/single_response_interceptor.dart';

part 'load_result.dart';
part 'data_observer.dart';
part 'with_listener_mixin.dart';

typedef ErrorHandler<E> = E Function(dynamic error);

class DataPageBase<T, R, E> with WithListenerMixin, WithDataObserverMixin<LoadResultPageBase<T, R, E>> {
  final _futureInterceptor = FutureInterceptor<R>();
  final _loadingInterceptor = LoadingInterceptor();
  late final PageResponseInterceptor<T, R> _responseInterceptor;
  late final ErrorInterceptor<E> _errorInterceptor;
  final ErrorHandler<E> errorHandler;
  Completer<FutureResponse<R>>? _cancelToken;
  FutureRequestOptions<R>? _options;

  List<T> get data => _responseInterceptor.data;
  int get initPage => _responseInterceptor.initPage;
  bool get isLastPage => _responseInterceptor.isLastPage;
  int get total => _responseInterceptor.total;
  int get page => _responseInterceptor.page;
  int get pageSize => _responseInterceptor.pageSize;
  LoadState get loadState => _loadingInterceptor.loadState;
  bool get isLoading => _loadingInterceptor.isLoading;
  E? get error => _errorInterceptor.error;

  DataPageBase({
    required this.errorHandler,
    List<T> Function(R result)? handleResult,
    bool Function(R result)? handleLastPage,
    final int Function(R result)? handleTotal,
    int pageSize = 40,
    int initPage = 0,
  }) {
    _errorInterceptor = ErrorInterceptor<E>(errorHandler: errorHandler);
    _responseInterceptor = PageResponseInterceptor<T, R>(
      handleResult: handleResult,
      handleLastPage: handleLastPage,
      handleTotal: handleTotal,
      pageSize: pageSize,
      initPage: initPage,
    );
    _futureInterceptor.interceptors.addAll([
      _loadingInterceptor,
      _responseInterceptor,
      _errorInterceptor,
    ]);
    _futureInterceptor.addListener(FutureListener(
        requestCallback: () {
          notifyListeners();
        },
        responseCallback: () {
          notifyListeners();
        }
    ));
  }

  void reset({bool pendingRefresh = false}) {
    _responseInterceptor.reset(pendingRefresh: pendingRefresh);
    _loadingInterceptor.reset();
    _errorInterceptor.reset();
    if (_cancelToken != null) {
      if (!_cancelToken!.isCompleted && _options != null) {
        _cancelToken!.complete(
          FutureResponse<R>(requestOptions: _options!),
        );
      }
      _cancelToken = null;
    }
    notifyListeners();
  }

  Future<LoadResultPageBase<T, R, E>> fetch(Future<R> Function() loadFunction, {dynamic extra}) async {
    if (_cancelToken != null) {
      return LoadResultPageBase<T, R, E>(
        isSkipped: true,
        isSuccess: false,
      );
    }
    final token = Completer<FutureResponse<R>>();
    _cancelToken = token;
    final option = FutureRequestOptions<R>(
      request: loadFunction,
    );
    _options = option;
    final future = _futureInterceptor.fetch(
      option,
    );
    final FutureResponse<R> res = await Future.any([
      token.future,
      future,
    ]);
    if (_options == option) {
      _options = null;
    }
    if (_cancelToken != token) {
      // cancelled
      return LoadResultPageBase<T, R, E>(
        response: null,
        data: null,
        isSuccess: false,
        isSkipped: true,
      );
    }
    this._cancelToken = null;
    LoadResultPageBase<T, R, E> ret;
    if (res.error == null) {
      ret = LoadResultPageBase<T, R, E>(
        response: res.data,
        data: _responseInterceptor.data,
        isSuccess: true,
        isSkipped: false,
      );
    } else {
      ret = LoadResultPageBase<T, R, E>(
        error: res.error?.error is E ? res.error?.error as E : errorHandler(res.error?.error),
        response: res.data,
        isSkipped: false,
        isSuccess: false,
      );
    }
    _notifyObserver(ret, extra);
    return ret;
  }
}

class DataPage<T, E> with WithDataObserverMixin<LoadResultPage<T, E>> {
  late final DataPageBase<T, List<T>, E> _dataPageBase;

  List<T> get data => _dataPageBase.data;
  int get initPage => _dataPageBase.initPage;
  bool get isLastPage => _dataPageBase.isLastPage;
  int get total => _dataPageBase.total;
  int get page => _dataPageBase.page;
  int get pageSize => _dataPageBase.pageSize;
  LoadState get loadState => _dataPageBase.loadState;
  bool get isLoading => _dataPageBase.isLoading;
  E? get error => _dataPageBase.error;
  Set<UpdateCallback> get listeners => _dataPageBase.listeners;

  void addListener(UpdateCallback listener) {
    _dataPageBase.addListener(listener);
  }

  void reset({bool pendingRefresh = false}) {
    _dataPageBase.reset();
  }

  DataPage({
    required final ErrorHandler<E> errorHandler,
    bool Function(List<T> result)? handleLastPage,
    int pageSize = 40,
    int initPage = 0,
  }) {
    _dataPageBase = DataPageBase<T, List<T>, E>(
      errorHandler: errorHandler,
      handleLastPage: handleLastPage,
      pageSize: pageSize,
      initPage: initPage,
    );
  }

  Future<LoadResultPage<T, E>> fetch(Future<List<T>> Function() loadFunction, {dynamic extra}) async {
    final res = await _dataPageBase.fetch(loadFunction, extra: extra);
    final ret = LoadResultPage(
      error: res.error,
      data: res.data,
      response: res.response,
      isSkipped: res.isSkipped,
      isSuccess: res.isSuccess,
    );
    _notifyObserver(ret, extra);
    return ret;
  }
}

class DataStore<T, E> with WithListenerMixin, WithDataObserverMixin<LoadResult<T, E>> {
  final _futureInterceptor = FutureInterceptor<T>();
  final _loadingInterceptor = LoadingInterceptor();
  final _responseInterceptor = SingleResponseInterceptor<T>();

  late ErrorInterceptor<E> _errorInterceptor;
  final ErrorHandler<E> errorHandler;
  T? get data => _responseInterceptor.data;
  E? get error => _errorInterceptor.error;
  LoadState get loadState => _loadingInterceptor.loadState;
  bool get isLoading => _loadingInterceptor.isLoading;
  Completer<FutureResponse<T>>? _cancelToken;
  FutureRequestOptions<T>? _options;

  DataStore({required this.errorHandler}) {
    _errorInterceptor = ErrorInterceptor<E>(errorHandler: errorHandler);
    _futureInterceptor.interceptors.addAll([
      _loadingInterceptor,
      _responseInterceptor,
      _errorInterceptor,
    ]);
    _futureInterceptor.addListener(FutureListener(
        requestCallback: () {
          notifyListeners();
        },
        responseCallback: () {
          notifyListeners();
        }
    ));
  }

  void reset({bool keepData = false}) {
    _responseInterceptor.reset(keepData: keepData);
    _loadingInterceptor.reset();
    _errorInterceptor.reset();
    if (_cancelToken != null) {
      if (!_cancelToken!.isCompleted && _options != null) {
        _cancelToken!.complete(
            FutureResponse<T>(requestOptions: _options!),
        );
      }
      _cancelToken = null;
    }
    notifyListeners();
  }

  Future<LoadResult<T, E>> fetch(Future<T> Function() loadFunction, {dynamic extra}) async {
    if (_cancelToken != null) {
      return LoadResult(
        isSkipped: true,
        isSuccess: false,
      );
    }
    final _token = Completer<FutureResponse<T>>();
    this._cancelToken = _token;
    final option = FutureRequestOptions<T>(request: loadFunction);
    _options = option;
    final future = _futureInterceptor.fetch(option);
    // wait for the first complete
    final res = await Future.any([
      _token.future,
      future,
    ]);
    if (_options == option) {
      _options = null;
    }
    if (_cancelToken != _token) {
      // cancelled
      return LoadResult<T, E>(
        data: null,
        isSkipped: true,
        isSuccess: false,
      );
    }
    this._cancelToken = null;
    LoadResult<T, E> ret;
    if (res.error == null) {
      ret = LoadResult<T, E>(
        data: res.data,
        isSkipped: false,
        isSuccess: true,
      );
    } else {
      ret = LoadResult<T, E>(
        error: res.error?.error is E ? res.error?.error as E : errorHandler(res.error?.error),
        isSkipped: false,
        isSuccess: false,
      );
    }
    _notifyObserver(ret, extra);
    return ret;
  }
}
