import 'dart:async';

part 'data_state.dart';
part 'page_state.dart';
part 'load_state.dart';
part 'with_listener_mixin.dart';

typedef ErrorHandler<E> = E Function(dynamic error);

class DataPageBase<T, R, E> with WithListenerMixin<PageState<T, E>>, WithResponseMixin<R> {
  DataPageBase({
    required ErrorHandler<E> errorHandler,
    List<T> Function(R result)? handleResult,
    bool Function(R result)? handleLastPage,
    final int Function(R result)? handleTotal,
    int pageSize = 40,
    int initPage = 0,
  })  : _errorHandler = errorHandler,
        _handleLastPage = handleLastPage,
        _handleResult = handleResult,
        _handleTotal = handleTotal,
        _state = PageState<T, E>(
          data: [],
          initPage: initPage,
          isLastPage: false,
          total: 0,
          page: initPage,
          pageSize: pageSize,
          loadState: LoadState.success,
        );

  late PageState<T, E> _state;
  PageState<T, E> get state => _state;
  void set state(PageState<T, E> value) {
    _state = value;
    notifyStateChanged(value);
  }
  final List<T> Function(R result)? _handleResult;
  final bool Function(R result)? _handleLastPage;
  final int Function(R result)? _handleTotal;
  final ErrorHandler<E> _errorHandler;
  final List<Completer<PageState<T, E>>> _pendingRequest = [];
  int _reqId = 0;

  void reset() {
    state = PageState<T, E>(
      data: [],
      initPage: state.initPage,
      isLastPage: false,
      total: 0,
      page: state.initPage,
      pageSize: state.pageSize,
      loadState: LoadState.success,
    );
    _resolveRequests(state);
    _reqId++;
  }

  void _resolveRequests(PageState<T, E> res) {
    for (var item in _pendingRequest) {
      item.complete(res);
    };
    _pendingRequest.clear();
  }

  Future<PageState<T, E>?> _fetchInternal(Future<R> Function() loadFunction, {dynamic extra}) async {
    PageState<T, E> ret;
    int currId = ++_reqId;
    bool success = true;
    try {
      state = state.copyWith(
          loadState: LoadState.loading
      );
      final R res = await loadFunction();
      if (currId != _reqId) {
        // The request has been canceled, no further processing will be performed
        return null;
      }
      notifyResponse(res);
      // process data
      List<T>? data;
      if (_handleResult != null) {
        data = _handleResult!.call(res);
      } else if (res is List<T>) {
        data = res;
      } else {
        throw Exception("Could not parse result: ${res}");
      }
      // process last page
      bool lastPage = false;
      if (_handleLastPage != null) {
        lastPage = _handleLastPage!.call(res);
      } else {
        lastPage = data.isEmpty;
      }
      // process total item
      int total = state.total;
      if (_handleTotal != null) {
        total = _handleTotal!.call(res);
      }
      // next page
      int page = state.page;
      page++;
      final allData = state.data;
      allData.addAll(data);
      ret = state.success(
        loadState: LoadState.success,
        data: allData,
        initPage: state.initPage,
        isLastPage: lastPage,
        total: total,
        page: page,
        pageSize: state.pageSize,
        rawResponse: res,
        error: null
      );
    } catch (e, st) {
      if (currId != _reqId) {
        // The request has been canceled, no further processing will be performed
        return null;
      }
      print("$e, $st");
      ret = state.copyWith(
        loadState: LoadState.error,
        error: _errorHandler(e),
        rawResponse: null,
      );
      success = false;
    }
    state = ret;
    if (!success) {
      notifyError(ret);
    }
    _resolveRequests(ret);
    return ret;
  }

  Future<PageState<T, E>> fetch(Future<R> Function() loadFunction, {dynamic extra}) {
    final completer = Completer<PageState<T, E>>();
    _pendingRequest.add(completer);
    if (state.loadState != LoadState.loading) {
      _fetchInternal(loadFunction, extra: extra);
    }
    return completer.future;
  }
}

class DataPage<T, E> extends DataPageBase<T, List<T>, E> {

  DataPage({
    required final ErrorHandler<E> errorHandler,
    bool Function(List<T> result)? handleLastPage,
    int pageSize = 40,
    int initPage = 0,
  }): super(
    errorHandler: errorHandler,
    handleLastPage: handleLastPage,
    pageSize: pageSize,
    initPage: initPage,
  );
}

class DataStore<T, E> with WithListenerMixin<DataState<T, E>> {
  DataStore({required ErrorHandler<E> errorHandler}): _errorHandler = errorHandler {
    _state = DataState<T, E>(loadState: LoadState.success);
  }

  late DataState<T, E> _state;
  DataState<T, E> get state => _state;
  void set state(DataState<T, E> value) {
    _state = value;
    notifyStateChanged(state);
  }
  final ErrorHandler<E> _errorHandler;
  final List<Completer<DataState<T, E>>> _pendingRequest = [];
  int _reqId = 0;

  void reset() {
    state = DataState<T, E>(
      data: null,
      loadState: LoadState.success,
    );
    _resolveRequests(state);
    _reqId++;
  }

  void _resolveRequests(DataState<T, E> res) {
    for (var item in _pendingRequest) {
      item.complete(res);
    };
    _pendingRequest.clear();
  }

  Future<DataState<T, E>?> _fetchInternal(Future<T> Function() loadFunction, {dynamic extra}) async {
    DataState<T, E> ret;
    int currId = ++_reqId;
    bool success = true;
    try {
      state = state.copyWith(
          loadState: LoadState.loading
      );
      final T res = await loadFunction();
      if (currId != _reqId) {
        // The request has been canceled, no further processing will be performed
        return null;
      }
      // process data
      ret = DataState<T, E>(
        data: res,
        loadState: LoadState.success,
      );
    } catch (e, st) {
      if (currId != _reqId) {
        // The request has been canceled, no further processing will be performed
        return null;
      }
      print("$e, $st");
      ret = DataState<T, E>(
        data: null,
        loadState: LoadState.error,
        error: _errorHandler(e),
      );
      success = false;
    }
    state = ret;
    if (!success) {
      notifyError(ret);
    }
    _resolveRequests(ret);
    return ret;
  }

  Future<DataState<T, E>> fetch(Future<T> Function() loadFunction, {dynamic extra}) {
    final completer = Completer<DataState<T, E>>();
    _pendingRequest.add(completer);
    if (state.loadState != LoadState.loading) {
      _fetchInternal(loadFunction, extra: extra);
    }
    return completer.future;
  }
}
