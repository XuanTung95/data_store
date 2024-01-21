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
  complexPage.addListener(() {
    print("loading ${store.isLoading}");
  });
  complexPage.addDataObserver((response, extra) {
    print("handle response ${response}");
  });

  final res = await complexPage.fetch(() async {
    return TestResponse(
      total: 99,
      lastPage: true,
      data: ["1", "2", "3"],
    );
  });
  print("""
      Response:
      error ${res.error}
      data ${res.data} // return List
      response ${res.response} // return TestResponse()
      isSuccess ${res.isSuccess}
      isSkipped ${res.isSkipped}
      
      State:
      all loaded data ${complexPage.data}
      isLoading ${complexPage.isLoading}
      current page ${complexPage.page}
      pageSize ${complexPage.pageSize}
      isLastPage ${complexPage.isLastPage}
      initPage ${complexPage.initPage}
      total item ${complexPage.total}
      last error ${complexPage.error}
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
  store.addListener(() {
    print("loading ${store.isLoading}");
  });
  store.addDataObserver((response, extra) {
    print("handle response ${response}");
  });
  /// No need to try catch
  final res = await store.fetch(() async {
    return "1";
  });
  print("data ${res.data}");
}

class TestResponse {
  final int total;
  final bool lastPage;
  final List<String> data;

  TestResponse({required this.total, required this.lastPage, required this.data});
}
```