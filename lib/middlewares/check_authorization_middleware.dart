import 'package:shelf/shelf.dart';

Middleware checkAuthorisation() {
  return createMiddleware(
    requestHandler: (Request request) {
      if (request.context['authDetails'] == null) {
        return Response.forbidden('Not authorised to perform this action.');
      }
      return null;
    },
  );
}
