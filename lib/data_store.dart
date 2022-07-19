library data_store;

typedef UpdateCallback = void Function();

class DataStore<T> {
  DataStore({PageParam? param}) : _param = param ?? PageParam();

  // PRIVATE FIELD
  final PageParam _param; // page and size
  dynamic _error; // last error
  final List<T> _data = [];
  bool _isDone = false;
  bool _isError = false;
  bool _isLoading = false;

  int _requestId = 0;
  int _newId() {
    _requestId++;
    return _requestId;
  }
  bool _isValidId(int id) => id == _requestId;

  final List<UpdateCallback> _listeners = []; // notify that ui should update

  // GETTER
  bool get isLoading => _isLoading;
  bool get _shouldRunLoadData => _isLoading == false && _isDone == false;
  dynamic get error => _error;
  bool get isError => _isError;
  List<T> get data => _data;
  int get nextPage => _param.page; // page number to put in request
  int get pageSize => _param.pageSize;
  bool get isDone => _isDone; // page size to get
  set isDone(bool value) {
    _isDone = value;
    _notifyListeners();
  }

  // METHODS
  void addListener(UpdateCallback listener) {
    _listeners.remove(listener);
    _listeners.add(listener);
  }

  void removeListener(UpdateCallback listener) {
    _listeners.remove(listener);
  }

  void removeAllListener() {
    _listeners.clear();
  }

  void reset() {
    _data.clear();
    _isDone = false;
    _isError = false;
    _isLoading = false;
    _error = null;
    _param.reset(); // reset page param
    _newId(); // abort the current request
    _notifyListeners();
  }

  void _loadSuccess(List<T>? data, bool isDone, {bool replace = false}) {
    _isLoading = false;
    _param.nextPage();
    if (replace) {
      _data.clear();
    }
    if (data != null) {
      _data.addAll(data);
    }
    _isDone = isDone;
    _error = null;
    _isError = false;
  }

  void _loadError({dynamic error}) {
    _isLoading = false;
    _error = error;
    _isError = true;
  }

  void _notifyListeners() {
    for (var item in _listeners) {
      item.call();
    }
  }

  ///
  /// Load data and return result
  /// Return null if the request is aborted
  ///
  Future<LoadResult<T>?> loadMoreData(
      {required Future<LoadResult<T>> Function() loadFunction, bool replace = false}) async {
    if (!_shouldRunLoadData) {
      return null;
    }
    LoadResult<T>? result;
    // new request id
    int id = _newId();
    bool success = false;
    dynamic error;
    try {
      _isLoading = true;
      // show loading
      _notifyListeners();

      result = await loadFunction();
      if (!_isValidId(id)) {
        // aborted -> return null without doing anything
        return null;
      }
      if (result.isSuccess) {
        _loadSuccess(result.data, result.isDone, replace: replace);
        success = true;
      } else {
        error = result.error;
      }
    } catch (e, st) {
      print("Load data failed with exception: $e: $st");
      error = e;
      result = LoadResult.error(error: e);
    }
    if (!success) {
      _loadError(error: error);
    }
    // update ui
    _notifyListeners();
    return result;
  }
}

class LoadResult<T> {
  final List<T>? data;
  final bool isDone;
  final dynamic error;
  final bool isSuccess;

  LoadResult.success({required this.data, this.isDone = false}): error = null, isSuccess = true;

  LoadResult.error({required this.error}): data = null, isSuccess = false, isDone = false;
}

class PageParam {
  int _page = 0;
  final int _pageSize;
  final int _initPage;

  int get page => _page;

  int get pageSize => _pageSize;

  int get initPage => _initPage;

  PageParam({int pageSize = 20, int initPage = 0})
      : _pageSize = pageSize,
        _initPage = initPage,
        _page = initPage;

  void nextPage() {
    _page++;
  }

  void reset() {
    _page = 0;
  }
}
