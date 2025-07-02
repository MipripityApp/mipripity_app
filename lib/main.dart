import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mipripity/invest_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:mipripity/screens/onboarding/agency_details_screen.dart';
import 'package:mipripity/screens/onboarding/interest_screen.dart';
import 'package:mipripity/screens/onboarding/personal_info_screen.dart';
import 'package:mipripity/screens/onboarding/profile_photo_screen.dart';
import 'package:mipripity/screens/onboarding/review_screen.dart';
import 'package:mipripity/screens/verify_cac_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'add_screen.dart';
import 'explore_screen.dart';
import 'location_details.dart';
import 'property_details_screen.dart';
import 'material_details.dart';
import 'register_screen.dart';
import 'skill_worker_details.dart';
import 'map_view.dart';
import 'package:provider/provider.dart';
import 'add_view_model.dart';
import 'providers/user_provider.dart';
import 'providers/onboarding_provider.dart';
import 'screens/onboarding/onboarding_wrapper.dart';
import 'chat_screen.dart';
import 'new_message_page.dart';
import 'inbox_screen.dart';
import 'my_listings_screen.dart';
import 'my_bids_screen.dart';
import 'get_coordinate_screen.dart';
import 'settings_screen.dart';
import 'investment_vendor_form.dart';
import 'forgot_password_screen.dart';


void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize WebView functionality
  WebViewPlatform.instance = WebViewPlatform.instance ?? AndroidWebViewPlatform();
  
  // Enable WebView debugging for development
  if (WebViewPlatform.instance is AndroidWebViewPlatform) {
    AndroidWebViewController.enableDebugging(true);
  }
  
  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBFUUu-CJ902phDcK_BWuKR6fiUgwzXb9I',
      appId: '1:579775767696:android:4007e4df501939061d2415',
      messagingSenderId: '579775767696',
      projectId: 'mipripity-signup',
      authDomain: 'mipripity-signup.firebaseapp.com',
      storageBucket: 'mipripity-signup.appspot.com',
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AddViewModel()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mipripity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF000080),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000080),
          primary: const Color(0xFF000080),
          secondary: const Color(0xFFF39322),
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/invest': (context) => const InvestInRealEstate(),
        '/add': (context) => AddScreen(
          onNavigateBack: () => Navigator.of(context).pop(),
        ),
        '/explore': (context) => const ExplorePage(),
        '/chat': (context) => const ChatPage(),
        '/new-message': (context) => const NewMessagePage(),
        '/inbox': (context) => const InboxScreen(),
        '/my-listings': (context) => const MyListingsScreen(),
        '/my-bids': (context) => const MyBidsScreen(),
        '/get-coordinate': (context) => const GetCoordinateScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/register': (context) => const RegisterScreen(),
        // Onboarding route is handled in onGenerateRoute to receive userData
        '/location-details': (context) => const LocationDetails(locationId: 'default'),
        '/property-details': (context) => const PropertyDetails(propertyId: 'default'),
        '/material-details': (context) => const MaterialDetails(materialId: 'default'),
        '/skill-worker-details': (context) => const SkillWorkerDetails(workerId: 'default'),
        '/personal-info': (context) => const PersonalInfoScreen(),
        '/interest-screen': (context) => const InterestScreen(),
        '/agency-details': (context) => const AgencyDetailsScreen(),
        '/profile-photo': (context) => const ProfilePhotoScreen(),
        '/review': (context) => const ReviewScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/investment-vendor-form': (context) => const InvestmentVendorForm(),
        '/verify-cac': (context) => const VerifyCacScreen(),
        '/map-view': (context) => const MapView(
          propertyId: 'default',
          propertyTitle: 'Property Location',
          propertyAddress: 'Lagos, Nigeria',
          latitude: 6.559668,
          longitude: 3.337714,
        ),

      },
      // For routes with parameters, we need to use onGenerateRoute
      onGenerateRoute: (settings) {
        // Handle dynamic routes
        if (settings.name == '/onboarding') {
          // Handle onboarding route with userData
          final userData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => OnboardingWrapper(userData: userData),
          );
        }
        else if (settings.name?.startsWith('/explore/') ?? false) {
          // Extract the location ID from the route
          final locationId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => LocationDetails(locationId: locationId),
          );
        } 
        else if (settings.name?.startsWith('/property-details/') ?? false) {
          // Extract the property ID from the route
          final propertyId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => PropertyDetails(propertyId: propertyId),
          );
        }
        else if (settings.name?.startsWith('/material/') ?? false) {
          // Extract the material ID from the route
          final materialId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => MaterialDetails(materialId: materialId),
          );
        }
        else if (settings.name?.startsWith('/skill-workers/') ?? false) {
          // Extract the worker ID from the route
          final workerId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => SkillWorkerDetails(workerId: workerId),
          );
        }
        // If no match, return null and let the routes table handle it
        return null;
      },
    );
  }
}
