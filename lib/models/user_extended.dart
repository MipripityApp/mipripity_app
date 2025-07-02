import 'user.dart';

class UserExtended extends User {
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? state;
  final String? lga;
  final List<String>? interests;
  final String? agencyName;
  final bool? agencyVerified;
  final String? rcNumber;
  final String? officialAgencyName;
  final bool onboardingCompleted;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserExtended({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.phoneNumber,
    super.whatsappLink,
    super.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.state,
    this.lga,
    this.interests,
    this.agencyName,
    this.agencyVerified,
    this.rcNumber,
    this.officialAgencyName,
    this.onboardingCompleted = false,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  // Check if user is a real estate agent based on interests
  bool get isRealEstateAgent {
    if (interests == null) return false;
    return interests!.any((interest) => 
      interest.toLowerCase().contains('agent') ||
      interest.toLowerCase().contains('realtor') ||
      interest.toLowerCase().contains('agency')
    );
  }

  // Create from basic user data (from registration)
  factory UserExtended.fromBasicUser(Map<String, dynamic> userData) {
    return UserExtended(
      id: userData['id'] ?? 0,
      email: userData['email'] ?? '',
      firstName: userData['first_name'] ?? userData['firstName'] ?? '',
      lastName: userData['last_name'] ?? userData['lastName'] ?? '',
      phoneNumber: userData['phone_number'] ?? userData['phoneNumber'] ?? '',
      whatsappLink: userData['whatsapp_link'] ?? userData['whatsappLink'],
      avatarUrl: userData['avatar_url'] ?? userData['avatarUrl'],
      bio: userData['bio'],
      createdAt: userData['created_at'] != null 
          ? DateTime.tryParse(userData['created_at']) 
          : null,
      updatedAt: userData['updated_at'] != null 
          ? DateTime.tryParse(userData['updated_at']) 
          : null,
    );
  }

  // Create from JSON
  factory UserExtended.fromJson(Map<String, dynamic> json) {
    return UserExtended(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      whatsappLink: json['whatsapp_link'] ?? json['whatsappLink'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.tryParse(json['date_of_birth']) 
          : null,
      address: json['address'],
      state: json['state'],
      lga: json['lga'],
      interests: json['interests'] != null 
          ? List<String>.from(json['interests']) 
          : null,
      agencyName: json['agency_name'] ?? json['agencyName'],
      agencyVerified: json['agency_verified'] ?? json['agencyVerified'],
      rcNumber: json['rc_number'] ?? json['rcNumber'],
      officialAgencyName: json['official_agency_name'] ?? json['officialAgencyName'],
      onboardingCompleted: json['onboarding_completed'] ?? json['onboardingCompleted'] ?? false,
      bio: json['bio'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  // Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'state': state,
      'lga': lga,
      'interests': interests,
      'agency_name': agencyName,
      'agency_verified': agencyVerified,
      'rc_number': rcNumber,
      'official_agency_name': officialAgencyName,
      'onboarding_completed': onboardingCompleted,
      'bio': bio,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    });
    return json;
  }

  // Copy with method for immutable updates
  UserExtended copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? whatsappLink,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? state,
    String? lga,
    List<String>? interests,
    String? agencyName,
    bool? agencyVerified,
    String? rcNumber,
    String? officialAgencyName,
    bool? onboardingCompleted,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserExtended(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappLink: whatsappLink ?? this.whatsappLink,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      state: state ?? this.state,
      lga: lga ?? this.lga,
      interests: interests ?? this.interests,
      agencyName: agencyName ?? this.agencyName,
      agencyVerified: agencyVerified ?? this.agencyVerified,
      rcNumber: rcNumber ?? this.rcNumber,
      officialAgencyName: officialAgencyName ?? this.officialAgencyName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
