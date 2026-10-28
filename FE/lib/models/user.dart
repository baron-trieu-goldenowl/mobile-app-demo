class User {
  final int id;
  final String email;
  final String? name;
  final String? avatarUrl;

  /// Linked sign-in providers: "google", "apple".
  final List<String> providers;
  final bool googleConnected;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.providers = const [],
    this.googleConnected = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      providers: (json['providers'] as List<dynamic>? ?? []).cast<String>(),
      googleConnected: json['google_connected'] as bool? ?? false,
    );
  }
}
