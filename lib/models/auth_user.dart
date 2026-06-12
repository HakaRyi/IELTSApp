class AuthUser {
  final String id;
  final String email;
  final String username;
  final String displayName;

  AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        username: json['username'] ?? '',
        displayName: json['displayName'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'displayName': displayName,
      };
}
