// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  profileImageUrl: json['profileImageUrl'] as String?,
  provider: $enumDecode(_$AuthProviderEnumMap, json['provider']),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'profileImageUrl': instance.profileImageUrl,
  'provider': _$AuthProviderEnumMap[instance.provider]!,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$AuthProviderEnumMap = {
  AuthProvider.google: 'google',
  AuthProvider.apple: 'apple',
  AuthProvider.kakao: 'kakao',
  AuthProvider.naver: 'naver',
};
