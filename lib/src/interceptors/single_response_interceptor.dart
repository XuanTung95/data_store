import 'package:future_interceptor/future_interceptor.dart';
import 'record_id_mixin.dart';

class SingleResponseInterceptor<T> extends Interceptor with RecordExtension, RecordId {
  T? _data;

  T? get data => _data;

  void reset({bool keepData = false}) {
    if (!keepData) {
      _data = null;
    }
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
        if (res.data == null || res.data is T) {
          _data = res.data;
        }
      }
    }
    return res;
  };
}