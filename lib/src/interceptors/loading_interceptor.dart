import 'package:future_interceptor/future_interceptor.dart';

import '../data_store.dart';
import 'record_id_mixin.dart';

class LoadingInterceptor extends Interceptor with RecordExtension, RecordId {
  LoadState _loadState = LoadState.success;

  LoadState get loadState => _loadState;

  bool get isLoading => _loadState == LoadState.loading;

  void reset() {
    _loadState = LoadState.success;
    clearIds();
  }

  @override
  InterceptorRequestCallback? get onRequest => (FutureRequestOptions options) {
    createNewId();
    _loadState = LoadState.loading;
    return options;
  };

  InterceptorTransformCallback? get onTransform => (res) {
    if (isValidId()) {
      removeId();
      if (ids.isEmpty) {
        if (res.error == null) {
          _loadState = LoadState.success;
        } else {
          _loadState = LoadState.error;
        }
      }
    }
    return res;
  };
}