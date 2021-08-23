class TokenPair {
  final String token;
  final String refreshToken;

  TokenPair(this.token, this.refreshToken);

  Map<String, dynamic> toJson() {
    return {'token': token, 'refreshToken': refreshToken};
  }
}
