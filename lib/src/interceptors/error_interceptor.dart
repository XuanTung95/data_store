import 'package:future_interceptor/future_interceptor.dart';

import '../data_store.dart';
import 'record_id_mixin.dart';

class ErrorInterceptor<E> extends Interceptor with RecordExtension, RecordId {

  ErrorInterceptor({required this.errorHandler});

  E? _error;

  E? get error => _error;

  final ErrorHandler<E> errorHandler;

  void reset() {
    _error = null;
    clearIds();
  }

  InterceptorRequestCallback? get onRequest => (FutureRequestOptions options) {
    createNewId();
    return options;
  };

  InterceptorTransformCallback? get onTransform => (res) {
    if (isValidId()) {
      removeId();
      if (res.error != null) {
        _error = errorHandler(res.error!.error);
        return FutureResponse(
          requestOptions: res.requestOptions,
          data: res.data,
          error: FutureException(
            error: _error,
          ),
        );
      } else {
        _error = null;
      }
    }
    return res;
  };
}