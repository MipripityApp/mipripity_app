import 'package:flutter/foundation.dart';

/// Extended User model with additional fields for the onboarding process
class UserExtended {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? whatsappLink;
  final String? avatarUrl;
  
  // Onboarding fields - Step 1: Interests
  final List<String>? interests; // Buyer, Seller, Agent, Realtor, Real Estate Agency, Mixed
  
  // Onboarding fields - Step 2: Personal Information
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? state;
  final String? lga; // Local Government Area
  
  // Onboarding fields - Step 3: Professional Details (conditional)
  final String? agencyName;
  final bool? agencyVerified;
  
  // Onboarding completion status
  final bool onboardingCompleted;

  UserExtended({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.whatsappLink,
    this.avatarUrl,
    this.interests,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.state,
    this.lga,
    this.agencyName,
    this.agencyVerified,
    this.onboardingCompleted = false,
  });

  factory UserExtended.fromJson(Map<String, dynamic> json) {
    return UserExtended(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      whatsappLink: json['whatsapp_link'] ?? json['whatsappLink'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      interests: json['interests'] != null 
          ? List<String>.from(json['interests']) 
          : null,
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      address: json['address'],
      state: json['state'],
      lga: json['lga'],
      agencyName: json['agency_name'] ?? json['agencyName'],
      agencyVerified: json['agency_verified'] ?? json['agencyVerified'],
      onboardingCompleted: json['onboarding_completed'] ?? json['onboardingCompleted'] ?? false,
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
      'interests': interests,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'state': state,
      'lga': lga,
      'agency_name': agencyName,
      'agency_verified': agencyVerified,
      'onboarding_completed': onboardingCompleted,
    };
  }
  
  // Helper to get full name
  String get fullName => '$firstName $lastName'.trim();
  
  // Helper to check if user is an agent or agency
  bool get isRealEstateAgent => 
      interests != null && 
      (interests!.contains('Agent') || 
       interests!.contains('Realtor') || 
       interests!.contains('Real Estate Agency'));
       
  // Create a copy of the user with updated fields
  UserExtended copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? whatsappLink,
    String? avatarUrl,
    List<String>? interests,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? state,
    String? lga,
    String? agencyName,
    bool? agencyVerified,
    bool? onboardingCompleted,
  }) {
    return UserExtended(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappLink: whatsappLink ?? this.whatsappLink,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interests: interests ?? this.interests,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      state: state ?? this.state,
      lga: lga ?? this.lga,
      agencyName: agencyName ?? this.agencyName,
      agencyVerified: agencyVerified ?? this.agencyVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
  
  // Convert basic User to UserExtended
  factory UserExtended.fromBasicUser(Map<String, dynamic> userData) {
    return UserExtended(
      id: userData['id'],
      email: userData['email'],
      firstName: userData['first_name'] ?? userData['firstName'],
      lastName: userData['last_name'] ?? userData['lastName'],
      phoneNumber: userData['phone_number'] ?? userData['phoneNumber'],
      whatsappLink: userData['whatsapp_link'] ?? userData['whatsappLink'],
      avatarUrl: userData['avatar_url'] ?? userData['avatarUrl'],
    );
  }
}