
part of 'data_store.dart';

typedef DataObserverCallback<T> = void Function(T response, dynamic extra);

mixin WithDataObserverMixin<T> {
  final Set<DataObserverCallback<T>> _observers = {};

  Set<DataObserverCallback<T>> get observers => _observers;

  void addDataObserver(DataObserverCallback<T> listener) {
    _observers.add(listener);
  }

  void _notifyObserver(T response, dynamic extra) {
    if (_observers.isNotEmpty) {
      for (var item in _observers) {
        try {
          item.call(response, extra);
        } catch (e) {
          // noop
        }
      }
    }
  }
}