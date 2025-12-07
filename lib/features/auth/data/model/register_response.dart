class RegisterResponse {
  final String userId;
  final String message;

  RegisterResponse({
    required this.userId,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json["userId"],
      message: json["message"] ?? "",
    );
  }
}
