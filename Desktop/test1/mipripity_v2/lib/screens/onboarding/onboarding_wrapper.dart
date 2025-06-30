import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import 'interest_screen.dart';
import 'personal_info_screen.dart';
import 'agency_details_screen.dart';
import 'profile_photo_screen.dart';
import 'review_screen.dart';

class OnboardingWrapper extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const OnboardingWrapper({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Initialize the onboarding provider with the user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
      onboardingProvider.initWithUser(widget.userData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, onboardingProvider, child) {
        // Check if user exists (it should after initWithUser)
        if (onboardingProvider.user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF39322),
              ),
            ),
          );
        }
        
        // Return the appropriate screen based on the current onboarding step
        switch (onboardingProvider.currentStep) {
          case OnboardingStep.interests:
            return const InterestScreen();
          
          case OnboardingStep.personalInfo:
            return const PersonalInfoScreen();
          
          case OnboardingStep.agencyDetails:
            // Only show agency details if user is an agent or agency
            if (onboardingProvider.user!.isRealEstateAgent) {
              return const AgencyDetailsScreen();
            } else {
              // Skip to profile photo screen if not an agent
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onboardingProvider.nextStep();
              });
              // Show loading while transitioning
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF39322),
                  ),
                ),
              );
            }
          
          case OnboardingStep.profilePhoto:
            return const ProfilePhotoScreen();
          
          case OnboardingStep.review:
            return const ReviewScreen();
          
          case OnboardingStep.completed:
            // Redirect to login screen if onboarding is completed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/login');
            });
            // Show loading while transitioning
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF39322),
                ),
              ),
            );
        }
      },
    );
  }
}