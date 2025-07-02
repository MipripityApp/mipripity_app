import 'package:flutter/material.dart';
import 'package:mipripity/dashboard_screen.dart';
import 'package:mipripity/explore_screen.dart';
import 'package:mipripity/invest_screen.dart';
import 'package:mipripity/my_bids_screen.dart';

class SharedBottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const SharedBottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72, // Fixed height for consistency across screens
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Only apply safe area to bottom
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                context,
                'home',
                'assets/icons/home.png',
                'Home',
              ),
              const SizedBox(width: 8), // Match category tab spacing
              _buildNavItem(
                context,
                'invest',
                'assets/icons/invest.png',
                'Invest',
              ),
              const SizedBox(width: 8),
              _buildAddButton(context),
              const SizedBox(width: 8),
              _buildNavItem(
                context,
                'bid',
                'assets/icons/bid.png',
                'Bid',
              ),
              const SizedBox(width: 8),
              _buildNavItem(
                context,
                'explore',
                'assets/icons/explore.png',
                'Explore',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String route,
    String iconAsset,
    String label,
  ) {
    final bool isSelected = activeTab == route;
    
    return SizedBox(
      width: 60, // Fixed width for consistency across items
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            onTabChange(route);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center items vertically
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageIcon(
              AssetImage(iconAsset),
              size: 24,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      height: 48, // Match height with nav items for vertical consistency
      child: Center(
        child: GestureDetector(
          onTap: () => onTabChange('add'),
          child: Container(
            width: 48,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF39322), Color(0xFF000080)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  // Custom page route with zero animation for bottom navigation
  static Route<T> _createNoAnimationRoute<T extends Object?>(
    Widget page,
    String routeName,
  ) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  // Shared navigation logic with zero animation
  static void handleNavigation(BuildContext context, String tab) {
    // Get current route name to prevent unnecessary navigation
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    
    switch (tab) {
      case 'home':
        const String targetRoute = '/dashboard';
        if (currentRoute != targetRoute) {
          Navigator.pushAndRemoveUntil(
            context,
            _createNoAnimationRoute(
              DashboardScreen(key: UniqueKey()),
              targetRoute,
            ),
            (route) => false,
          );
        }
        break;
      case 'invest':
        const String targetRoute = '/invest';
        if (currentRoute != targetRoute) {
          Navigator.pushAndRemoveUntil(
            context,
            _createNoAnimationRoute(
              InvestInRealEstate(key: UniqueKey()),
              targetRoute,
            ),
            (route) => false,
          );
        }
        break;
      case 'add':
        // The add screen should still be opened as a modal with normal animation
        Navigator.pushNamed(context, '/add');
        break;
      case 'bid':
        const String targetRoute = '/my-bids';
        if (currentRoute != targetRoute) {
          Navigator.pushAndRemoveUntil(
            context,
            _createNoAnimationRoute(
              MyBidsScreen(key: UniqueKey()),
              targetRoute,
            ),
            (route) => false,
          );
        }
        break;
      case 'explore':
        const String targetRoute = '/explore';
        if (currentRoute != targetRoute) {
          Navigator.pushAndRemoveUntil(
            context,
            _createNoAnimationRoute(
              ExplorePage(key: UniqueKey()),
              targetRoute,
            ),
            (route) => false,
          );
        }
        break;
    }
  }
}