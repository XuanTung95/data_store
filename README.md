Provide a safe place to call API and handle errors. Support data observer and listener.

## Usage

```dart
/// Create a class to manage error
class MyErrorClass {
  final dynamic error;

  String getErrorMessage() {
    return '$error';
  }

  MyErrorClass({required this.error});
}

/// Specify how to convert from any exception to MyErrorClass
MyErrorClass myErrorHandler(dynamic error) {
  return MyErrorClass(error: error);
}

/// Pagination
Future fetchComplexPage() async {
  final complexPage = DataPageBase<String, TestResponse, MyErrorClass>(
      errorHandler: myErrorHandler,
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
  complexPage.addStateChangeListener((state) {
    print("loading ${state.isLoading}");
  });
  complexPage.addResponseListener((response) {
    print("handle response ${response}");
  });
  /// No need to try catch
  final state = await complexPage.fetch(() async {
    return TestResponse(
      total: 99,
      lastPage: true,
      data: ["1", "2", "3"],
    );
  });
  print("""
      State:
      all loaded data ${state.data}
      isLoading ${state.isLoading}
      current page ${state.page}
      pageSize ${state.pageSize}
      isLastPage ${state.isLastPage}
      initPage ${state.initPage}
      total item ${state.total}
      last error ${state.error}
  """);
}

Future fetchSimplePage() async {
  final page = DataPage(errorHandler: myErrorHandler);
  final res = await page.fetch(() async {
    return ["1", "2", "3"];
  });
  print("data ${res.data}");
}

/// Normal api call
Future fetchData() async {
  final store = DataStore(errorHandler: myErrorHandler);
  store.addStateChangeListener((state) {
    print("loading ${state.isLoading}");
  });
  store.addErrorListener((error) {
    print("handle error ${error}");
  });
  final state = await store.fetch(() async {
    return "1";
  });
  print("""
      State:
      data ${state.data}
      isLoading ${state.isLoading}
      last error ${state.error}
  """);
}

class TestResponse {
  final int total;
  final bool lastPage;
  final List<String> data;

  TestResponse({required this.total, required this.lastPage, required this.data});
}
```