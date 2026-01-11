class FailureModel {
  final String message;
  final int? code;
  final dynamic details;

  const FailureModel({
    required this.message,
    this.code,
    this.details,
  });

  factory FailureModel.fromJson(Map<String, dynamic> json) {
    return FailureModel(
      message: json['message'] ?? '',
      code: json['code'] as int?,
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (code != null) 'code': code,
      if (details != null) 'details': details,
    };
  }

  factory FailureModel.fromException(Object e, {int? code}) {
    return FailureModel(message: e.toString(), code: code, details: e);
  }

  @override
  String toString() => 'FailureModel(message: $message, code: $code)';
}