import 'package:shelf/shelf.dart';

import '../utils/utils.dart';

Middleware authMiddleware(String secret) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      var token, jwt;

      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
        print(token);
        jwt = verifyJwt(token, secret);
      }

      final updatedRequest = request.change(context: {
        'authDetails': jwt,
      });
      return await innerHandler(updatedRequest);
    };
  };
}
