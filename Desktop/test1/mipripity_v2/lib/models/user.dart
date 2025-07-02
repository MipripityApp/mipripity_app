class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? whatsappLink;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.whatsappLink,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      whatsappLink: json['whatsapp_link'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'whatsapp_link': whatsappLink,
      'avatar_url': avatarUrl,
    };
  }
  
  // Helper to get full name
  String get fullName => '$firstName $lastName'.trim();
}