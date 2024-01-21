import 'package:future_interceptor/future_interceptor.dart';
import 'record_id_mixin.dart';

class PageResponseInterceptor<T, R> extends Interceptor with RecordExtension, RecordId {
  final List<T> _data = [];
  int _page = 0;
  int _pageSize = 20;
  int _initPage = 0;
  int _total = 0;
  bool _pendingRefresh = false;
  bool _isLastPage = false;

  List<T> get data => _data;
  int get page => _page;
  int get total => _total;
  int get pageSize => _pageSize;
  int get initPage => _initPage;
  bool get pendingRefresh => _pendingRefresh;
  bool get isLastPage => _isLastPage;

  final List<T> Function(R result)? handleResult;
  final bool Function(R result)? handleLastPage;
  final int Function(R result)? handleTotal;

  PageResponseInterceptor({
    int pageSize = 40,
    int initPage = 0,
    this.handleResult,
    this.handleLastPage,
    this.handleTotal,
  })  : _pageSize = pageSize,
        _initPage = initPage,
        _page = initPage;

  void reset({bool pendingRefresh = false}) {
    if (!pendingRefresh) {
      _data.clear();
    }
    _pendingRefresh = pendingRefresh;
    _isLastPage = false;
    _page = _initPage;
    _total = 0;
    clearIds();
  }

  @override
  InterceptorRequestCallback? get onRequest => (FutureRequestOptions options) {
    createNewId();
    return options;
  };

  InterceptorTransformCallback? get onTransform => (res) {
    if (isValidId()) {
      removeId();
      if (res.error == null) {
        if (res.data is R) {
          // process data
          List<T>? data;
          if (handleResult != null) {
            data = handleResult!.call(res.data);
          } else if (res.data is List<T>) {
            data = res.data;
          } else {
            return FutureResponse(
              data: null,
              error: FutureException(
                error: Exception("Could not parse result: ${res.data}"),
              ),
              requestOptions: res.requestOptions,
            );
          }
          // process last page
          bool lastPage = false;
          if (handleLastPage != null) {
            lastPage = handleLastPage!.call(res.data);
          } else {
            lastPage = data!.isEmpty;
          }
          _isLastPage = lastPage;
          // process total item
          if (handleTotal != null) {
            _total = handleTotal!.call(res.data);
          }
          // next page
          _page++;
          if (_pendingRefresh) {
            _data.clear();
            _data.addAll(data!);
          } else {
            _data.addAll(data!);
          }
        }
      }
    }
    return res;
  };
}