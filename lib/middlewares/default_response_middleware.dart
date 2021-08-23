import 'package:shelf/shelf.dart';

Middleware defaultResponseContentType(String contentType) {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);

      final mapHeaders = {...response.headers, 'content-type': contentType};
      return response.change(headers: mapHeaders);
    };
  };
}
