/// Request DTO for the login API endpoint.
class LoginRequestModel {
  const LoginRequestModel({
    required this.email,
    required this.password,
    this.deviceId,
  });

  final String email;
  final String password;

  /// Optional device identifier for session tracking.
  final String? deviceId;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (deviceId != null) 'device_id': deviceId,
      };
}

/// Request DTO for the registration API endpoint.
class RegisterRequestModel {
  const RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.deviceId,
  });

  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? deviceId;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'password': password,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (deviceId != null) 'device_id': deviceId,
      };
}

/// Request DTO for the password reset endpoint.
class ForgotPasswordRequestModel {
  const ForgotPasswordRequestModel({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

/// Request DTO for the Google sign-in endpoint.
class GoogleSignInRequestModel {
  const GoogleSignInRequestModel({
    required this.idToken,
    this.deviceId,
  });

  final String idToken;
  final String? deviceId;

  Map<String, dynamic> toJson() => {
        'id_token': idToken,
        if (deviceId != null) 'device_id': deviceId,
      };
}
