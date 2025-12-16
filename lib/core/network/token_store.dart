class TokenStore {
  final String? accessToken;
  final String? refreshToken;

  const TokenStore({this.accessToken, this.refreshToken});

  bool get hasBoth =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty;

  @override
  String toString() =>
      "TokenStore(access=$accessToken, refresh=$refreshToken)";
}
