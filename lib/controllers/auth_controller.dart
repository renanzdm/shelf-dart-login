import 'dart:convert';
import 'dart:io';

import 'package:DartBackend/services/token_service.dart';
import 'package:DartBackend/utils/utils.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AuthController {
  DbCollection store;
  String secret;
  TokenService tokenService;
  AuthController(
      {required this.store, required this.secret, required this.tokenService});

  Router get router {
    final router = Router();
    router.post('/register', (Request req) async {
      final payload = await req.readAsString();
      final userInfo = json.decode(payload);
      String? email = userInfo['email'];
      String? password = userInfo['password'];

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        return Response(HttpStatus.badRequest, body: 'Informe email e senha');
      }
      final user = await store.findOne(where.eq('email', email));
      if (user != null) {
        return Response(HttpStatus.badRequest,
            body: 'Email ja esta cadastrado');
      }
      final salt = generateSalt();
      final hashedPassword = hashPassword(password, salt);
      await store.insertOne(
          {'email': email, 'password': hashedPassword, 'salt': salt});

      return Response.ok('Register Sucessfull');
    });

    router.post('/login', (Request req) async {
      final payload = await req.readAsString();
      final userInfo = json.decode(payload);
      String? email = userInfo['email'];
      String? password = userInfo['password'];
      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        return Response(HttpStatus.badRequest, body: 'Informe email e senha');
      }

      final user = await store.findOne(where.eq('email', email));
      final hashedPassword = hashPassword(password, user?['salt'] ?? '');
      if (hashedPassword != user?['password']) {
        return Response.forbidden('Password incorreto');
      }
      final userId = (user?['_id'] as ObjectId).toHexString();
      try {
        final tokenPair = await tokenService.createTokenPair(userId);
        return Response.ok(json.encode(tokenPair.toJson()), headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.mimeType
        });
      } catch (e) {
        return Response.internalServerError(body: 'Erro interno no servidor');
      }
    });

    router.post('/logout', (Request req) async {
      final auth = req.context['authDetails'];
      if (auth == null) {
        return Response.forbidden('Operacao nao autorizada');
      }
      try {
        await tokenService.removeRefreshToken((auth as JWT).jwtId);
      } catch (e) {
        print(e);
        return Response.internalServerError(
            body: 'Erro interno no servidor ao deslogar');
      }

      return Response.ok('Successfully logged out');
    });

    router.post('/refreshToken', (Request req) async {
      final payload = await req.readAsString();
      final payloadMap = json.decode(payload);

      final refreshToken = payloadMap['refreshToken'].toString().substring(7);
      final token = verifyJwt(refreshToken, secret);
      if (token == null) {
        return Response(400, body: 'Refresh token nao esta valido.');
      }

      final dbToken = await tokenService.getRefreshToken((token as JWT).jwtId);
      if (dbToken == null) {
        return Response(400, body: 'Refresh token nao e reconhecido.');
      }

      // Generate new token pair
      final oldJwt = token;
      try {
        await tokenService.removeRefreshToken((token).jwtId);

        final tokenPair = await tokenService.createTokenPair(oldJwt.subject!);
        return Response.ok(
          json.encode(tokenPair.toJson()),
          headers: {
            HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
          },
        );
      } catch (e) {
        return Response.internalServerError(
            body: 'Problema em criar em um novo token, tente novamente');
      }
    });

    return router;
  }
}
