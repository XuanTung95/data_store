part of 'data_store.dart';

typedef StateChangeCallback<T> = void Function(T state);

mixin WithListenerMixin<T> {
  final Set<StateChangeCallback<T>> _stateChangeListeners = {};
  final Set<StateChangeCallback<T>> _errorListeners = {};

  Set<StateChangeCallback<T>> get stateChangeListeners => _stateChangeListeners;
  Set<StateChangeCallback<T>> get errorListeners => _errorListeners;

  void addStateChangeListener(StateChangeCallback<T> listener) {
    _stateChangeListeners.add(listener);
  }

  void addErrorListener(StateChangeCallback<T> listener) {
    _errorListeners.add(listener);
  }

  void notifyStateChanged(T state) {
    if (_stateChangeListeners.isNotEmpty) {
      for (var item in _stateChangeListeners) {
        try {
          item.call(state);
        } catch (e, st) {
          print("$e, $st");
        }
      }
    }
  }

  void notifyError(T state) {
    if (_errorListeners.isNotEmpty) {
      for (var item in _errorListeners) {
        try {
          item.call(state);
        } catch (e, st) {
          print("$e, $st");
        }
      }
    }
  }
}

mixin WithResponseMixin<T> {
  final Set<StateChangeCallback<T>> _responseListeners = {};

  Set<StateChangeCallback<T>> get responseListeners => _responseListeners;

  void addResponseListener(StateChangeCallback<T> listener) {
    _responseListeners.add(listener);
  }

  void notifyResponse(T response) {
    if (_responseListeners.isNotEmpty) {
      for (var item in _responseListeners) {
        try {
          item.call(response);
        } catch (e, st) {
          print("$e, $st");
        }
      }
    }
  }
}