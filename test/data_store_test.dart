import 'package:api_data_store/api_data_store.dart';
import 'package:test/test.dart';

void main() {
  late DataStore<dynamic, TestApiError> store;
  late DataPage<dynamic, TestApiError> page;
  late DataPageBase<String, TestResponse, TestApiError> pageBase;

  setUp(() {
    store = DataStore(errorHandler: globalErrorHandler);
    page = DataPage(errorHandler: globalErrorHandler);
    pageBase = DataPageBase(
        errorHandler: globalErrorHandler,
        handleResult: (res) {
          return res.data;
        },
        handleTotal: (res) {
          return res.total;
        },
        handleLastPage: (res) {
          return res.lastPage;
        });
  });

  group('DataStore', () {
    _clearListener() {
      store.stateChangeListeners.clear();
      store.errorListeners.clear();
    }

    test('Success', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      List<TestApiError?> error2 = [];
      store.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error);
        data.add(state.data);
      });
      store.addErrorListener((state) {
        error2.add(state.error);
      });
      final res = await store.fetch(() async {
        return "1";
      });
      expect(res.data, "1");
      expect(res.error, null);
      expect(count, 2);
      expect(error2.isEmpty, true);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null]), true);
      expect(listEqual(data, [null, "1"]), true);
    });

    test('Error', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> error2 = [];
      List<dynamic> data = [];
      store.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error);
        data.add(state.data);
      });
      store.addErrorListener((state) {
        error2.add(state.error?.error);
      });
      final res = await store.fetch(() async {
        throw "error";
      });
      expect(res.data, null);
      expect(res.error?.error, "error");
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error]), true);
      expect(listEqual(error, [null, res.error]), true);
      expect(listEqual(error2, ["error"]), true);
      expect(listEqual(data, [null, null]), true);
    });

    test('Reset', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> error2 = [];
      List<dynamic> data = [];
      store.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error);
        data.add(state.data);
      });
      store.addErrorListener((state) {
        error2.add(state.error?.error);
      });
      final f = store.fetch(() async {
        throw "error";
      });
      store.reset();
      expect(store.state.data, null);
      expect(store.state.loadState, LoadState.success);
      expect(store.state.error, null);
      final res = await f;
      expect(store.state.data, null);
      expect(store.state.loadState, LoadState.success);
      expect(store.state.error, null);

      expect(res.data, null);
      expect(res.error, null);
      expect(count, 2);
      expect(listEqual(error2, []), true);
      expect(listEqual(error, [null, null]), true);
      expect(listEqual(data, [null, null]), true);
    });

    test('Reset Multiple request', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> error2 = [];
      List<dynamic> data = [];
      store.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error);
        data.add(state.data);
      });
      store.addErrorListener((state) {
        error2.add(state.error?.error);
      });
      final f = store.fetch(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return "1";
      });
      await Future.delayed(Duration(milliseconds: 30));
      store.reset();
      final f2 = store.fetch(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return "2";
      });
      final res = await f;
      final res2 = await f2;

      expect(store.state.data, "2");
      expect(store.state.loadState, LoadState.success);
      expect(store.state.error, null);

      expect(res.data, null);
      expect(res.error, null);

      expect(res2.data, "2");
      expect(res2.error, null);

      expect(count, 4);
      expect(listEqual(error, [null, null, null, null]), true);
      expect(listEqual(error2, []), true);
      expect(listEqual(data, [null, null, null, "2"]), true);
      expect(
          listEqual(loadState, [
            LoadState.loading,
            LoadState.success,
            LoadState.loading,
            LoadState.success,
          ]),
          true);
    });
  });

  group('DataPage', () {
    _clearListener() {
      page.stateChangeListeners.clear();
      page.errorListeners.clear();
      page.responseListeners.clear();
    }

    test('Success', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> error2 = [];
      List<dynamic> data = [];
      List<dynamic> data2 = [];
      page.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error);
        data.addAll(state.data);
      });
      page.addErrorListener((state) {
        error2.add(state.error?.error);
      });
      page.addResponseListener((res) {
        data2.add(res);
      });
      int ret = 1;
      final res = await page.fetch(() async {
        return ["${ret++}"];
      });
      expect(listEqual(page.state.data, ["1"]), true);
      expect(listEqual(res.data, ["1"]), true);
      expect(res.error, null);
      expect(page.state.page, 1);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, false);
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null]), true);
      expect(listEqual(error2, []), true);
      expect(data2.length, 1);

      final res2 = await page.fetch(() async {
        return ["${ret++}"];
      });

      expect(listEqual(page.state.data, ["1", "2"]), true);
      expect(listEqual(res2.rawResponse ?? [], ["2"]), true);
      expect(listEqual(res2.data, ["1", "2"]), true);
      expect(res2.error, null);
      expect(page.state.page, 2);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, false);
      expect(count, 4);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success, LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null, null, null]), true);
      expect(listEqual(error2, []), true);
      expect(data2.length, 2);

      final res3 = await page.fetch(() async {
        return [];
      });

      expect(listEqual(page.state.data, ["1", "2"]), true);
      expect(listEqual(res3.rawResponse ?? [], []), true);
      expect(listEqual(res3.data, ["1", "2"]), true);
      expect(page.state.isLoading, false);
      expect(res3.error, null);
      expect(page.state.page, 3);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, true);
      expect(count, 6);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success, LoadState.loading, LoadState.success, LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null, null, null, null, null]), true);
      expect(listEqual(error2, []), true);
      expect(data2.length, 3);
    });

    test('Error', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<dynamic> error = [];
      List<dynamic> error2 = [];
      List<dynamic> data = [];
      List<dynamic> data2 = [];
      page.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error?.error);
        data.addAll(state.data);
      });
      page.addErrorListener((state) {
        error2.add(state.error?.error);
      });
      page.addResponseListener((res) {
        data2.add(res);
      });
      int ret = 1;
      final res = await page.fetch(() async {
        throw "e";
      });
      expect(listEqual(page.state.data, []), true);
      expect(listEqual(res.data, []), true);
      expect(res.error?.error, "e");
      expect(page.state.page, 0);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, false);
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error]), true);
      expect(listEqual(error, [null, "e"]), true);
      expect(listEqual(error2, ["e"]), true);
      expect(listEqual(data2, []), true);

      final res2 = await page.fetch(() async {
        return ["${ret++}"];
      });

      expect(listEqual(page.state.data, ["1"]), true);
      expect(listEqual(res2.rawResponse ?? [], ["1"]), true);
      expect(listEqual(res2.data, ["1"]), true);
      expect(res2.error, null);
      expect(page.state.page, 1);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, false);
      expect(count, 4);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error, LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, "e", "e", null]), true);
      expect(listEqual(error2, ["e"]), true);
      expect(data2.length, 1);

      final res3 = await page.fetch(() async {
        return [];
      });

      expect(listEqual(page.state.data, ["1"]), true);
      expect(listEqual(res3.rawResponse ?? [], []), true);
      expect(listEqual(res3.data, ["1"]), true);
      expect(page.state.isLoading, false);
      expect(res3.error, null);
      expect(page.state.page, 2);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, true);
      expect(count, 6);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error, LoadState.loading, LoadState.success, LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, "e", "e", null, null, null]), true);
      expect(listEqual(error2, ["e"]), true);
      expect(data2.length, 2);
    });

    test('Reset', () async {
      _clearListener();
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      page.addStateChangeListener((state) {
        loadState.add(state.loadState);
        error.add(state.error);
        data.addAll(state.data);
      });
      int ret = 1;
      await page.fetch(() async {
        return ["${ret++}"];
      });
      expect(listEqual(page.state.data, ["1"]), true);

      page.reset();
      expect(listEqual(page.state.data, []), true);
      expect(page.state.page, 0);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, false);

      final res2 = await page.fetch(() async {
        return ["${ret++}"];
      });

      expect(listEqual(page.state.data, ["2"]), true);
      expect(listEqual(res2.rawResponse ?? [], ["2"]), true);
      expect(listEqual(res2.data, ["2"]), true);
      expect(res2.error, null);
      expect(page.state.page, 1);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, false);
    });

    test('Reset Multiple request', () async {
      _clearListener();
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      page.addStateChangeListener((state) {
        loadState.add(state.loadState);
        error.add(state.error);
        data.addAll(state.data);
      });
      page.reset();
      int ret = 1;
      await page.fetch(() async {
        return ["${ret++}"];
      });
      expect(listEqual(page.state.data, ["1"]), true);

      page.reset();
      expect(listEqual(page.state.data, []), true);
      expect(page.state.page, 0);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, false);

      await page.fetch(() async {
        return ["${ret++}"];
      });
      await page.fetch(() async {
        return [];
      });

      expect(listEqual(page.state.data, ["2"]), true);
      expect(page.state.page, 2);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, true);

      page.reset();
      expect(listEqual(page.state.data, []), true);
      expect(page.state.page, 0);
      expect(page.state.total, 0);
      expect(page.state.isLastPage, false);
    });
  });

  group('DataPageBase', () {
    _clearListener() {
      pageBase.stateChangeListeners.clear();
    }

    test('Success', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> error2 = [];
      List<String> data = [];
      List<TestResponse> data2 = [];
      pageBase.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error);
        data.addAll(state.data);
      });
      pageBase.addErrorListener((state) {
        error2.add(state.error?.error);
      });
      pageBase.addResponseListener((res) {
        data2.add(res);
      });
      final res = await pageBase.fetch(() async {
        return TestResponse(
          total: 99,
          lastPage: true,
          data: ["1", "2", "3"],
        );
      });
      expect(listEqual(pageBase.state.data, ["1", "2", "3"]), true);
      expect(listEqual(res.data, ["1", "2", "3"]), true);
      expect(res.error, null);
      expect(pageBase.state.page, 1);
      expect(pageBase.state.total, 99);
      expect(pageBase.state.isLastPage, true);
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null]), true);
      expect(listEqual(error2, []), true);
      expect(data2.length, 1);
      loadState.clear();
      error.clear();

      final res2 = await pageBase.fetch(() async {
        return TestResponse(
          total: 88,
          lastPage: false,
          data: ["4", "5", "6"],
        );
      });

      expect(
          listEqual(pageBase.state.data, [
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
          ]),
          true);
      expect(listEqual(res2.rawResponse?.data ?? [], ["4", "5", "6"]), true);
      expect(
          listEqual(res2.data, [
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
          ]),
          true);
      expect(res2.error, null);
      expect(pageBase.state.page, 2);
      expect(pageBase.state.total, 88);
      expect(pageBase.state.isLastPage, false);
      expect(count, 4);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null]), true);
      expect(listEqual(error2, []), true);
      expect(data2.length, 2);

      final res3 = await pageBase.fetch(() async {
        return TestResponse(
          total: 69,
          lastPage: true,
          data: [],
        );
      });

      expect(
          listEqual(pageBase.state.data, [
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
          ]),
          true);
      expect(listEqual(res3.rawResponse?.data ?? [], []), true);
      expect(
          listEqual(res3.data, [
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
          ]),
          true);
      expect(pageBase.state.isLoading, false);
      expect(res3.error, null);
      expect(pageBase.state.page, 3);
      expect(pageBase.state.total, 69);
      expect(pageBase.state.isLastPage, true);
      expect(count, 6);
      expect(listEqual(error2, []), true);
      expect(data2.length, 3);
    });

    test('Error', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<dynamic> error = [];
      List<dynamic> error2 = [];
      List<String> data = [];
      List<TestResponse> data2 = [];
      pageBase.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error?.error);
        data.addAll(state.data);
      });
      pageBase.addErrorListener((state) {
        error2.add(state.error?.error);
      });
      pageBase.addResponseListener((res) {
        data2.add(res);
      });
      final res = await pageBase.fetch(() async {
        return TestResponse(
          total: 99,
          lastPage: true,
          data: ["1", "2", "3"],
        );
      });
      expect(listEqual(pageBase.state.data, ["1", "2", "3"]), true);
      expect(res.error, null);
      expect(pageBase.state.page, 1);
      expect(pageBase.state.total, 99);
      expect(pageBase.state.isLastPage, true);
      expect(error2.isEmpty, true);
      expect(data2.length, 1);
      loadState.clear();
      error.clear();

      final res2 = await pageBase.fetch(() async {
        throw "myError";
      });

      expect(listEqual(pageBase.state.data, ["1", "2", "3"]), true);
      expect(listEqual(res2.rawResponse?.data ?? [], []), true);
      expect(listEqual(res2.data, ["1", "2", "3"]), true);
      expect(res2.error?.error, "myError");
      expect(pageBase.state.page, 1);
      expect(pageBase.state.total, 99);
      expect(pageBase.state.isLastPage, true);
      expect(count, 4);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error]), true);
      expect(listEqual(error, [null, "myError"]), true);
      expect(listEqual(error2, ["myError"]), true);
      expect(data2.length, 1);

      final _ = await pageBase.fetch(() async {
        return TestResponse(
          total: 69,
          lastPage: true,
          data: ["4"],
        );
      });

      expect(listEqual(pageBase.state.data, ["1", "2", "3", "4"]), true);
      expect(pageBase.state.isLoading, false);
      expect(pageBase.state.error, null);
      expect(pageBase.state.page, 2);
      expect(pageBase.state.total, 69);
      expect(pageBase.state.isLastPage, true);
      expect(count, 6);
      expect(listEqual(error2, ["myError"]), true);
      expect(data2.length, 2);
    });

    test('Reset', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<dynamic> error = [];
      List<String> data = [];
      pageBase.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error?.error);
        data.addAll(state.data);
      });
      final res = await pageBase.fetch(() async {
        return TestResponse(
          total: 99,
          lastPage: true,
          data: ["1", "2", "3"],
        );
      });
      expect(listEqual(pageBase.state.data, ["1", "2", "3"]), true);
      expect(res.error, null);
      expect(pageBase.state.page, 1);
      expect(pageBase.state.total, 99);
      expect(pageBase.state.isLastPage, true);
      loadState.clear();
      error.clear();

      pageBase.reset();

      expect(listEqual(pageBase.state.data, []), true);
      expect(pageBase.state.page, 0);
      expect(pageBase.state.loadState, LoadState.success);
      expect(pageBase.state.error, null);
      expect(pageBase.state.total, 0);
      expect(pageBase.state.isLastPage, false);
      expect(count, 3);
    });

    test('Reset ongoing request', () async {
      _clearListener();
      int count = 0;
      List<LoadState> loadState = [];
      List<dynamic> error = [];
      List<String> data = [];
      pageBase.addStateChangeListener((state) {
        count++;
        loadState.add(state.loadState);
        error.add(state.error?.error);
        data.addAll(state.data);
      });
      final f1 = pageBase.fetch(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return TestResponse(
          total: 99,
          lastPage: true,
          data: ["1", "2", "3"],
        );
      });
      await Future.delayed(Duration(milliseconds: 30));
      expect(listEqual(pageBase.state.data, []), true);
      pageBase.reset();
      expect(listEqual(pageBase.state.data, []), true);
      final res = await f1;
      expect(listEqual(pageBase.state.data, []), true);
      expect(res.error, null);
      expect(pageBase.state.page, 0);
      expect(pageBase.state.total, 0);
      expect(pageBase.state.isLastPage, false);
      expect(count, 2);

      final _ = await pageBase.fetch(() async {
        return TestResponse(
          total: 69,
          lastPage: true,
          data: ["1"],
        );
      });
      expect(listEqual(pageBase.state.data, ["1"]), true);
      expect(pageBase.state.page, 1);
      expect(count, 4);

      pageBase.reset();
      expect(listEqual(pageBase.state.data, []), true);
      expect(pageBase.state.page, 0);
    });
  });
}

class TestResponse {
  final int total;
  final bool lastPage;
  final List<String> data;

  TestResponse({required this.total, required this.lastPage, required this.data});
}

TestApiError globalErrorHandler(dynamic error) {
  return TestApiError(error: error);
}

class TestApiError {
  final dynamic error;

  TestApiError({required this.error});
}

bool listEqual(List a, List b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
