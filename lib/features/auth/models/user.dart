import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final AuthProvider provider;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.provider,
    required this.createdAt,
  });

  /// JSON에서 객체로 변환
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

/// 인증 제공자
enum AuthProvider {
  @JsonValue('google')
  google,
  @JsonValue('apple')
  apple,
  @JsonValue('kakao')
  kakao,
  @JsonValue('naver')
  naver,
}