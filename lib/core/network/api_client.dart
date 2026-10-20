/// Placeholder API boundary. UI currently uses local demo data only.
/// Set [baseUrl] and implement repository methods when backend integration begins.
class ApiClient {
  ApiClient({this.baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api')});

  final String baseUrl;

  // Future<T> get<T>(String path) async { ... }
  // Future<T> post<T>(String path, Map<String, Object?> body) async { ... }
}
