import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SalesController {
  Router get router {
    final router = Router();

    router.get('/', (Request req) {
      return Response.ok('Sucesso');
    });

    return router;
  }
}
