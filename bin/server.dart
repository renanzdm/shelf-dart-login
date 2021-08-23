import 'package:DartBackend/config/config.dart';
import 'package:DartBackend/controllers/auth_controller.dart';
import 'package:DartBackend/controllers/user_controller.dart';
import 'package:DartBackend/middlewares/auth_middleware.dart';
import 'package:DartBackend/middlewares/cors_middleware.dart';
import 'package:DartBackend/services/token_service.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:redis/redis.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

Future<void> main(List<String> args) async {
  const secret = Env.secretKey;
  final db = Db(Env.mongodbUrl);
  final tokenService = TokenService(RedisConnection(), secret);

  await db.open();

  await tokenService.start(Env.redisHost, int.parse(Env.redisPort));
  print('Tokem service is running');

  final store = db.collection('user');
  final app = Router();

  app.mount(
      '/auth/',
      AuthController(store: store, secret: secret, tokenService: tokenService)
          .router);
  app.mount('/user/', UserController(store).router);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(handleCors())
      .addMiddleware(authMiddleware(secret))
      .addHandler(app);

  await serve(handler, '127.0.0.1', int.parse(Env.serverPort));
  print('HTTP Service running on port ${Env.serverPort}');
}
