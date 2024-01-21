import 'package:future_interceptor/future_interceptor.dart';

mixin RecordId on RecordExtension {
  Set<Object> _ids = {};
  Set<Object> get ids => _ids;

  Object createNewId() {
    final currId = getId();
    if (currId != null) {
      _ids.remove(currId);
    }
    final id = Object();
    setRecord(id);
    _ids.add(id);
    return id;
  }

  dynamic getId() {
    return record;
  }

  void removeId([Object? id]) {
    if (id != null) {
      _ids.remove(id);
    } else {
      _ids.remove(getId());
    }
    setRecord(null);
  }

  bool isValidId([Object? id]) {
    if (id != null) {
      return _ids.contains(id);
    } else {
      return _ids.contains(getId());
    }
  }

  void clearIds() {
    _ids.clear();
    setRecord(null);
  }
}