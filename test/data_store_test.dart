import 'package:data_store/data_store.dart';
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
      }
    );
  });

  group('DataStore', () {
    test('Success', () async {
      store.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      store.addListener(() {
        count++;
        loadState.add(store.loadState);
        error.add(store.error);
        data.add(store.data);
      });
      final res = await store.fetch(() async {
        return "1";
      });
      expect(res.data, "1");
      expect(res.error, null);
      expect(res.isSkipped, false);
      expect(res.isSuccess, true);
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null]), true);
      expect(listEqual(data, [null, "1"]), true);
    });

    test('Error', () async {
      store.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      store.addListener(() {
        count++;
        loadState.add(store.loadState);
        error.add(store.error);
        data.add(store.data);
      });
      final res = await store.fetch(() async {
        throw "error";
      });
      expect(res.data, null);
      expect(res.error?.error, "error");
      expect(res.isSkipped, false);
      expect(res.isSuccess, false);
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error]), true);
      expect(listEqual(error, [null, res.error]), true);
      expect(listEqual(data, [null, null]), true);
    });

    test('Reset', () async {
      store.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      store.addListener(() {
        count++;
        loadState.add(store.loadState);
        error.add(store.error);
        data.add(store.data);
      });
      final f = store.fetch(() async {
        throw "error";
      });
      store.reset();
      expect(store.data, null);
      expect(store.loadState, LoadState.success);
      expect(store.error, null);
      final res = await f;
      expect(store.data, null);
      expect(store.loadState, LoadState.success);
      expect(store.error, null);

      expect(res.data, null);
      expect(res.error, null);
      expect(res.isSkipped, true);
      expect(res.isSuccess, false);
      expect(count, 3);
      expect(listEqual(error, [null, null, null]), true);
      expect(listEqual(data, [null, null, null]), true);
    });

    test('Reset Multiple request', () async {
      store.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      store.addListener(() {
        count++;
        loadState.add(store.loadState);
        error.add(store.error);
        data.add(store.data);
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

      expect(store.data, "2");
      expect(store.loadState, LoadState.success);
      expect(store.error, null);

      expect(res.data, null);
      expect(res.error, null);
      expect(res.isSkipped, true);
      expect(res.isSuccess, false);

      expect(res2.data, "2");
      expect(res2.error, null);
      expect(res2.isSkipped, false);
      expect(res2.isSuccess, true);

      expect(count, 5);
      expect(listEqual(error, [null, null, null, null, null]), true);
      expect(listEqual(data, [null, null, null, null, "2"]), true);
      expect(
          listEqual(loadState, [
            LoadState.loading,
            LoadState.success,
            LoadState.loading,
            LoadState.loading,
            LoadState.success,
          ]),
          true);
    });
  });

  group('DataPage', () {
    test('Success', () async {
      page.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      page.addListener(() {
        count++;
        loadState.add(page.loadState);
        error.add(page.error);
        data.addAll(page.data);
      });
      int ret = 1;
      final res = await page.fetch(() async {
        return ["${ret++}"];
      });
      expect(listEqual(page.data, ["1"]), true);
      expect(listEqual(res.data ?? [], ["1"]), true);
      expect(res.error, null);
      expect(page.page, 1);
      expect(page.total, 0);
      expect(page.isLastPage, false);
      expect(res.isSkipped, false);
      expect(res.isSuccess, true);
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null]), true);

      final res2 = await page.fetch(() async {
        return ["${ret++}"];
      });

      expect(listEqual(page.data, ["1", "2"]), true);
      expect(listEqual(res2.response ?? [], ["2"]), true);
      expect(listEqual(res2.data ?? [], ["1", "2"]), true);
      expect(res2.error, null);
      expect(page.page, 2);
      expect(page.total, 0);
      expect(page.isLastPage, false);
      expect(res2.isSkipped, false);
      expect(res2.isSuccess, true);
      expect(count, 4);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success, LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null, null, null]), true);

      final res3 = await page.fetch(() async {
        return [];
      });

      expect(listEqual(page.data, ["1", "2"]), true);
      expect(listEqual(res3.response ?? [], []), true);
      expect(listEqual(res3.data ?? [], ["1", "2"]), true);
      expect(page.isLoading, false);
      expect(res3.error, null);
      expect(res3.isSkipped, false);
      expect(res3.isSuccess, true);
      expect(page.page, 3);
      expect(page.total, 0);
      expect(page.isLastPage, true);
      expect(count, 6);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success, LoadState.loading, LoadState.success, LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null, null, null, null, null]), true);
    });

    test('Error', () async {
      page.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<dynamic> error = [];
      List<dynamic> data = [];
      page.addListener(() {
        count++;
        loadState.add(page.loadState);
        error.add(page.error?.error);
        data.addAll(page.data);
      });
      int ret = 1;
      final res = await page.fetch(() async {
        throw "e";
      });
      expect(listEqual(page.data, []), true);
      expect(listEqual(res.data ?? [], []), true);
      expect(res.error?.error, "e");
      expect(page.page, 0);
      expect(page.total, 0);
      expect(page.isLastPage, false);
      expect(res.isSkipped, false);
      expect(res.isSuccess, false);
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error]), true);
      expect(listEqual(error, [null, "e"]), true);

      final res2 = await page.fetch(() async {
        return ["${ret++}"];
      });

      expect(listEqual(page.data, ["1"]), true);
      expect(listEqual(res2.response ?? [], ["1"]), true);
      expect(listEqual(res2.data ?? [], ["1"]), true);
      expect(res2.error, null);
      expect(page.page, 1);
      expect(page.total, 0);
      expect(page.isLastPage, false);
      expect(res2.isSkipped, false);
      expect(res2.isSuccess, true);
      expect(count, 4);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error, LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, "e", "e", null]), true);

      final res3 = await page.fetch(() async {
        return [];
      });

      expect(listEqual(page.data, ["1"]), true);
      expect(listEqual(res3.response ?? [], []), true);
      expect(listEqual(res3.data ?? [], ["1"]), true);
      expect(page.isLoading, false);
      expect(res3.error, null);
      expect(res3.isSkipped, false);
      expect(res3.isSuccess, true);
      expect(page.page, 2);
      expect(page.total, 0);
      expect(page.isLastPage, true);
      expect(count, 6);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error, LoadState.loading, LoadState.success, LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, "e", "e", null, null, null]), true);
    });

    test('Reset', () async {
      page.listeners.clear();
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      page.addListener(() {
        loadState.add(page.loadState);
        error.add(page.error);
        data.addAll(page.data);
      });
      int ret = 1;
      await page.fetch(() async {
        return ["${ret++}"];
      });
      expect(listEqual(page.data, ["1"]), true);

      page.reset();
      expect(listEqual(page.data, []), true);
      expect(page.page, 0);
      expect(page.total, 0);
      expect(page.isLastPage, false);

      final res2 = await page.fetch(() async {
        return ["${ret++}"];
      });

      expect(listEqual(page.data, ["2"]), true);
      expect(listEqual(res2.response ?? [], ["2"]), true);
      expect(listEqual(res2.data ?? [], ["2"]), true);
      expect(res2.error, null);
      expect(page.page, 1);
      expect(page.total, 0);
      expect(page.isLastPage, false);
      expect(res2.isSkipped, false);
      expect(res2.isSuccess, true);
    });

    test('Reset Multiple request', () async {
      page.listeners.clear();
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<dynamic> data = [];
      page.addListener(() {
        loadState.add(page.loadState);
        error.add(page.error);
        data.addAll(page.data);
      });
      page.reset();
      int ret = 1;
      await page.fetch(() async {
        return ["${ret++}"];
      });
      expect(listEqual(page.data, ["1"]), true);

      page.reset();
      expect(listEqual(page.data, []), true);
      expect(page.page, 0);
      expect(page.total, 0);
      expect(page.isLastPage, false);

      await page.fetch(() async {
        return ["${ret++}"];
      });
      await page.fetch(() async {
        return [];
      });

      expect(listEqual(page.data, ["2"]), true);
      expect(page.page, 2);
      expect(page.total, 0);
      expect(page.isLastPage, true);

      page.reset();
      expect(listEqual(page.data, []), true);
      expect(page.page, 0);
      expect(page.total, 0);
      expect(page.isLastPage, false);
    });
  });

  group('DataPageBase', () {
    test('Success', () async {
      pageBase.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<TestApiError?> error = [];
      List<String> data = [];
      pageBase.addListener(() {
        count++;
        loadState.add(pageBase.loadState);
        error.add(pageBase.error);
        data.addAll(pageBase.data);
      });
      final res = await pageBase.fetch(() async {
        return TestResponse(
          total: 99,
          lastPage: true,
          data: ["1", "2", "3"],
        );
      });
      expect(listEqual(pageBase.data, ["1", "2", "3"]), true);
      expect(listEqual(res.data ?? [], ["1", "2", "3"]), true);
      expect(res.error, null);
      expect(pageBase.page, 1);
      expect(pageBase.total, 99);
      expect(pageBase.isLastPage, true);
      expect(res.isSkipped, false);
      expect(res.isSuccess, true);
      expect(count, 2);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null]), true);
      loadState.clear();
      error.clear();

      final res2 = await pageBase.fetch(() async {
        return TestResponse(
          total: 88,
          lastPage: false,
          data: ["4", "5", "6"],
        );
      });

      expect(listEqual(pageBase.data, ["1", "2", "3", "4", "5", "6",]), true);
      expect(listEqual(res2.response?.data ?? [], ["4", "5", "6"]), true);
      expect(listEqual(res2.data ?? [], ["1", "2", "3", "4", "5", "6",]), true);
      expect(res2.error, null);
      expect(pageBase.page, 2);
      expect(pageBase.total, 88);
      expect(pageBase.isLastPage, false);
      expect(res2.isSkipped, false);
      expect(res2.isSuccess, true);
      expect(count, 4);
      expect(listEqual(loadState, [LoadState.loading, LoadState.success]), true);
      expect(listEqual(error, [null, null]), true);

      final res3 = await pageBase.fetch(() async {
        return TestResponse(
          total: 69,
          lastPage: true,
          data: [],
        );
      });

      expect(listEqual(pageBase.data, ["1", "2", "3", "4", "5", "6",]), true);
      expect(listEqual(res3.response?.data ?? [], []), true);
      expect(listEqual(res3.data ?? [], ["1", "2", "3", "4", "5", "6",]), true);
      expect(pageBase.isLoading, false);
      expect(res3.error, null);
      expect(res3.isSkipped, false);
      expect(res3.isSuccess, true);
      expect(pageBase.page, 3);
      expect(pageBase.total, 69);
      expect(pageBase.isLastPage, true);
      expect(count, 6);
    });

    test('Error', () async {
      pageBase.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<dynamic> error = [];
      List<String> data = [];
      pageBase.addListener(() {
        count++;
        loadState.add(pageBase.loadState);
        error.add(pageBase.error?.error);
        data.addAll(pageBase.data);
      });
      final res = await pageBase.fetch(() async {
        return TestResponse(
          total: 99,
          lastPage: true,
          data: ["1", "2", "3"],
        );
      });
      expect(listEqual(pageBase.data, ["1", "2", "3"]), true);
      expect(res.error, null);
      expect(pageBase.page, 1);
      expect(pageBase.total, 99);
      expect(pageBase.isLastPage, true);
      loadState.clear();
      error.clear();

      final res2 = await pageBase.fetch(() async {
        throw "myError";
      });

      expect(listEqual(pageBase.data, ["1", "2", "3"]), true);
      expect(listEqual(res2.response?.data ?? [], []), true);
      expect(listEqual(res2.data ?? [], []), true);
      expect(res2.error?.error, "myError");
      expect(pageBase.page, 1);
      expect(pageBase.total, 99);
      expect(pageBase.isLastPage, true);
      expect(res2.isSkipped, false);
      expect(res2.isSuccess, false);
      expect(count, 4);
      expect(listEqual(loadState, [LoadState.loading, LoadState.error]), true);
      expect(listEqual(error, [null, "myError"]), true);

      final res3 = await pageBase.fetch(() async {
        return TestResponse(
          total: 69,
          lastPage: true,
          data: ["4"],
        );
      });

      expect(listEqual(pageBase.data, ["1", "2", "3", "4"]), true);
      expect(pageBase.isLoading, false);
      expect(pageBase.error, null);
      expect(res3.isSkipped, false);
      expect(res3.isSuccess, true);
      expect(pageBase.page, 2);
      expect(pageBase.total, 69);
      expect(pageBase.isLastPage, true);
      expect(count, 6);
    });

    test('Reset', () async {
      pageBase.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<dynamic> error = [];
      List<String> data = [];
      pageBase.addListener(() {
        count++;
        loadState.add(pageBase.loadState);
        error.add(pageBase.error?.error);
        data.addAll(pageBase.data);
      });
      final res = await pageBase.fetch(() async {
        return TestResponse(
          total: 99,
          lastPage: true,
          data: ["1", "2", "3"],
        );
      });
      expect(listEqual(pageBase.data, ["1", "2", "3"]), true);
      expect(res.error, null);
      expect(pageBase.page, 1);
      expect(pageBase.total, 99);
      expect(pageBase.isLastPage, true);
      loadState.clear();
      error.clear();

      pageBase.reset();

      expect(listEqual(pageBase.data, []), true);
      expect(pageBase.page, 0);
      expect(pageBase.loadState, LoadState.success);
      expect(pageBase.error, null);
      expect(pageBase.total, 0);
      expect(pageBase.isLastPage, false);
      expect(count, 3);
    });

    test('Reset ongoing request', () async {
      pageBase.listeners.clear();
      int count = 0;
      List<LoadState> loadState = [];
      List<dynamic> error = [];
      List<String> data = [];
      pageBase.addListener(() {
        count++;
        loadState.add(pageBase.loadState);
        error.add(pageBase.error?.error);
        data.addAll(pageBase.data);
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
      expect(listEqual(pageBase.data, []), true);
      pageBase.reset();
      expect(listEqual(pageBase.data, []), true);
      final res = await f1;
      expect(listEqual(pageBase.data, []), true);
      expect(res.error, null);
      expect(pageBase.page, 0);
      expect(pageBase.total, 0);
      expect(pageBase.isLastPage, false);
      expect(count, 2);
      expect(res.isSkipped, true);
      expect(res.isSuccess, false);

      final res2 = await pageBase.fetch(() async {
        return TestResponse(
          total: 69,
          lastPage: true,
          data: ["1"],
        );
      });
      expect(listEqual(pageBase.data, ["1"]), true);
      expect(pageBase.page, 1);
      expect(res2.isSuccess, true);
      expect(count, 4);

      pageBase.reset();
      expect(listEqual(pageBase.data, []), true);
      expect(pageBase.page, 0);
    });
  });

  group('Observer', () {
    test('DataStore', () async {
      store.listeners.clear();
      store.observers.clear();
      List<LoadResult> responses = [];
      List<dynamic> extras = [];
      store.addDataObserver((response, extra) {
        responses.add(response);
        extras.add(extra);
      });
      await store.fetch(() async {
        return "1";
      }, extra: "e1");
      expect(responses.length, 1);
      expect(extras.length, 1);
      expect(responses[0].data, "1");
      expect(extras[0], "e1");
      await store.fetch(() async {
        throw "error";
      }, extra: "e2");
      expect(responses.length, 2);
      expect(extras.length, 2);
      expect(responses[1].error?.error, "error");
      expect(extras[1], "e2");
      await store.fetch(() async {
        return "2";
      }, extra: "e3");
      expect(responses.length, 3);
      expect(extras.length, 3);
      expect(responses[2].data, "2");
      expect(extras[2], "e3");
    });

    test('DataPage', () async {
      page.listeners.clear();
      page.observers.clear();
      List<LoadResultPage<dynamic, TestApiError>> responses = [];
      List<dynamic> extras = [];
      page.addDataObserver((response, extra) {
        responses.add(response);
        extras.add(extra);
      });
      await page.fetch(() async {
        return ["1"];
      }, extra: "e1");
      expect(responses.length, 1);
      expect(extras.length, 1);
      expect(listEqual(responses[0].data ?? [], ["1"]), true);
      expect(extras[0], "e1");
      await page.fetch(() async {
        throw "error";
      }, extra: "e2");
      expect(responses.length, 2);
      expect(extras.length, 2);
      expect(responses[1].error?.error, "error");
      expect(extras[1], "e2");
      await page.fetch(() async {
        return ["2"];
      }, extra: "e3");
      expect(responses.length, 3);
      expect(extras.length, 3);
      expect(listEqual(responses[0].data ?? [], ["1", "2"]), true);
      expect(extras[2], "e3");
    });

    test('DataPageBase', () async {
      pageBase.listeners.clear();
      pageBase.observers.clear();
      List<LoadResultPageBase<String, TestResponse, TestApiError>> responses = [];
      List<dynamic> extras = [];
      pageBase.addDataObserver((response, extra) {
        responses.add(response);
        extras.add(extra);
      });
      await pageBase.fetch(() async {
        return TestResponse(
          total: 99,
          lastPage: false,
          data: ["1"],
        );
      }, extra: "e1");
      expect(responses.length, 1);
      expect(extras.length, 1);
      expect(listEqual(responses[0].data ?? [], ["1"]), true);
      expect(extras[0], "e1");
      await pageBase.fetch(() async {
        throw "error";
      }, extra: "e2");
      expect(responses.length, 2);
      expect(extras.length, 2);
      expect(responses[1].error?.error, "error");
      expect(extras[1], "e2");
      await pageBase.fetch(() async {
        return TestResponse(
          total: 99,
          lastPage: false,
          data: ["2"],
        );
      }, extra: "e3");
      expect(responses.length, 3);
      expect(extras.length, 3);
      expect(listEqual(responses[0].data ?? [], ["1", "2"]), true);
      expect(extras[2], "e3");
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
