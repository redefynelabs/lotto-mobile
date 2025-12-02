class Validators {
  static bool isPhone(String value) =>
      RegExp(r'^[0-9]{10}$').hasMatch(value);

  static bool isOTP(String value) =>
      RegExp(r'^[0-9]{4,6}$').hasMatch(value);
}
