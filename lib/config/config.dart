import 'package:envify/envify.dart';
part '../config.g.dart';

@Envify()
abstract class Env {
  static const mongodbUrl = _Env.mongodbUrl;
  static const secretKey = _Env.secretKey;
  static const serverPort = _Env.serverPort;
  static const redisPort = _Env.redisPort;
  static const redisHost = _Env.redisHost;
}
