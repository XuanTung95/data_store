part of 'data_store.dart';

typedef UpdateCallback = void Function();

mixin WithListenerMixin {
  final Set<UpdateCallback> _listeners = {};

  Set<UpdateCallback> get listeners => _listeners;

  void addListener(UpdateCallback listener) {
    _listeners.add(listener);
  }

  void notifyListeners() {
    if (_listeners.isNotEmpty) {
      for (var item in _listeners) {
        item.call();
      }
    }
  }
}