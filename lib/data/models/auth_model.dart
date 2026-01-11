import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents authentication-related data for a user.
class AuthModel {
	final String uid;
	final String? email;
	final bool isEmailVerified;
	final String providerId;
	final String? idToken;
	final String? accessToken;
	final String? refreshToken;
	final DateTime? expiresAt;

	AuthModel({
		required this.uid,
		this.email,
		this.isEmailVerified = false,
		required this.providerId,
		this.idToken,
		this.accessToken,
		this.refreshToken,
		this.expiresAt,
	});

	Map<String, dynamic> toMap() {
		return {
			'email': email,
			'isEmailVerified': isEmailVerified,
			'providerId': providerId,
			'idToken': idToken,
			'accessToken': accessToken,
			'refreshToken': refreshToken,
			'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
		}..removeWhere((_, v) => v == null);
	}

	factory AuthModel.fromMap(String uid, Map<String, dynamic> map) {
		return AuthModel(
			uid: uid,
			email: map['email'] as String?,
			isEmailVerified: map['isEmailVerified'] as bool? ?? false,
			providerId: map['providerId'] as String? ?? 'password',
			idToken: map['idToken'] as String?,
			accessToken: map['accessToken'] as String?,
			refreshToken: map['refreshToken'] as String?,
			expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
		);
	}

	AuthModel copyWith({
		String? uid,
		String? email,
		bool? isEmailVerified,
		String? providerId,
		String? idToken,
		String? accessToken,
		String? refreshToken,
		DateTime? expiresAt,
	}) {
		return AuthModel(
			uid: uid ?? this.uid,
			email: email ?? this.email,
			isEmailVerified: isEmailVerified ?? this.isEmailVerified,
			providerId: providerId ?? this.providerId,
			idToken: idToken ?? this.idToken,
			accessToken: accessToken ?? this.accessToken,
			refreshToken: refreshToken ?? this.refreshToken,
			expiresAt: expiresAt ?? this.expiresAt,
		);
	}
}

