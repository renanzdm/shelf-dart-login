import 'package:DartBackend/models/token_pair.dart';
import 'package:DartBackend/utils/utils.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:redis/redis.dart';

class TokenService {
  final RedisConnection db;
  final String secret;

  TokenService(this.db, this.secret);

  static Command? _cache;
  final String _prefix = 'token';

  Future<void> start(String host, int port) async {
    _cache = await db.connect(host, port);
  }

  Future<TokenPair> createTokenPair(String userId) async {
    final tokenId = Uuid().v4();
    final durationExpires = const Duration(seconds: 60);
    final token =
        generateJwt(userId, 'http://127.0.0.1', secret, jwtId: tokenId);
    final refreshToken = generateJwt(userId, 'http://127.0.0.1', secret,
        jwtId: tokenId, expiry: const Duration(seconds: 60));

    await addRefreshToken(tokenId, refreshToken, durationExpires);
    return TokenPair(token, refreshToken);
  }

  Future<void> addRefreshToken(String id, String token, Duration expiry) async {
    await _cache?.send_object(['SET', '$_prefix:$id', token]);
    await _cache?.send_object(['EXPIRE', '$_prefix:$id', expiry.inSeconds]);
  }

  Future<dynamic> getRefreshToken(String? id) async {
    return await _cache?.get('$_prefix:$id');
  }

  Future<void> removeRefreshToken(String? id) async {
    await _cache?.send_object(['EXPIRE', '$_prefix:$id', '-1']);
  }
}
