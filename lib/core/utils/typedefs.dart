import 'package:dio/dio.dart';

// Generic typedefs for common use cases
typedef ResultFuture<T> = Future<T>;
typedef ResultStream<T> = Stream<T>;
typedef DataMap = Map<String, dynamic>;
typedef DataList = List<Map<String, dynamic>>;

// HTTP typedefs
typedef HttpHeaders = Map<String, String>;
typedef HttpQueryParams = Map<String, dynamic>;
typedef HttpBody = Map<String, dynamic>;

// Callback typedefs
typedef VoidCallback = void Function();
typedef ValueCallback<T> = void Function(T value);
typedef FutureCallback<T> = Future<T> Function();
typedef StreamCallback<T> = Stream<T> Function();

// Error handling
typedef ErrorHandler = void Function(Object error, StackTrace stackTrace);
typedef DioErrorHandler = void Function(DioException error);
