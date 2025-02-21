class User {
  final String username;
  final String firstName;
  final String lastName;
  final String enterprise;
  final String token;

  User({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.enterprise,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      username: json['user_name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      enterprise: json['enterprise'],
      token: token,
    );
  }
}
