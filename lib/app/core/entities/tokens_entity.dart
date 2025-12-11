// Tokens entity for authentication tokens
import 'dart:convert';

/// Entity representing authentication tokens
class TokensEntity {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? tokenType;
  final int? expiresIn;
  final Map<String, dynamic>? metadata;

  const TokensEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.tokenType,
    this.expiresIn,
    this.metadata,
  });

  /// Create tokens from API response
  factory TokensEntity.fromApiResponse(Map<String, dynamic> json) {
    return TokensEntity(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String?,
      expiresIn: json['expires_in'] as int?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(
              Duration(seconds: json['expires_in'] as int? ?? 3600),
            ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create tokens with calculated expiry
  factory TokensEntity.withExpiry({
    required String accessToken,
    required String refreshToken,
    required Duration expiresIn,
    String? tokenType,
    Map<String, dynamic>? metadata,
  }) {
    return TokensEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(expiresIn),
      tokenType: tokenType,
      expiresIn: expiresIn.inSeconds,
      metadata: metadata,
    );
  }

  /// Check if access token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if access token is valid (not expired)
  bool get isValid => !isExpired;

  /// Check if tokens need refresh (expiring within 5 minutes)
  bool get needsRefresh {
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiresAt);
  }

  /// Get time remaining until expiry
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  /// Get formatted time remaining
  String get timeRemainingFormatted {
    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays} day${remaining.inDays == 1 ? '' : 's'}';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hour${remaining.inHours == 1 ? '' : 's'}';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minute${remaining.inMinutes == 1 ? '' : 's'}';
    } else {
      return '${remaining.inSeconds} second${remaining.inSeconds == 1 ? '' : 's'}';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'token_type': tokenType,
      'expires_in': expiresIn,
      'metadata': metadata,
    };
  }

  /// Create copy with updated tokens
  TokensEntity copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tokenType,
    int? expiresIn,
    Map<String, dynamic>? metadata,
  }) {
    return TokensEntity(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'TokensEntity(accessToken: ${accessToken.substring(0, 10)}..., expiresAt: $expiresAt, isValid: $isValid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TokensEntity &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return accessToken.hashCode ^ refreshToken.hashCode ^ expiresAt.hashCode;
  }
}
