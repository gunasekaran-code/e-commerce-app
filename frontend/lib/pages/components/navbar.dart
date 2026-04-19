// import 'package:flutter/material.dart';
// import '../search_page.dart';   
// import '../wishlist_page.dart'; 
// import '../profile_page.dart'; 
// import '../home_page.dart';

// class UserHomePage extends StatefulWidget {
//   final Map<String, dynamic> userData;
//   const UserHomePage({super.key, required this.userData});

//   @override
//   State<UserHomePage> createState() => _UserHomePageState();
// }

// class _UserHomePageState extends State<UserHomePage> {
//   int _selectedIndex = 0;

//   void _onItemTapped(int index) {
//     setState(() => _selectedIndex = index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFDF7F7),
//       body: SafeArea(
//         child: IndexedStack(
//           index: _selectedIndex,
//           children: [
//             HomePage(userData: widget.userData), 
//             const SearchPage(),
//             const WishlistPage(),
//             ProfilePage(userData: widget.userData),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border(
//             top: BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
//           ),
//         ),
//         child: BottomNavigationBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: const Color(0xFFE4252A), // kBrandRed
//           unselectedItemColor: const Color(0xFF6B6B6B), // kTextMuted
//           currentIndex: _selectedIndex,
//           onTap: _onItemTapped,
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.home_filled),      label: 'Home'),
//             BottomNavigationBarItem(icon: Icon(Icons.search),            label: 'Search'),
//             BottomNavigationBarItem(icon: Icon(Icons.favorite_border),   label: 'Favorites'),
//             BottomNavigationBarItem(icon: Icon(Icons.person_outline),    label: 'Profile'),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../search_page.dart';
import '../wishlist_page.dart';
import '../profile_page.dart';
import '../home_page.dart';

class UserHomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserHomePage({super.key, required this.userData});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Helper widget to handle the unselected text labels and selected icon scaling
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF6B6B6B),
          size: isSelected ? 30 : 26, // Make the active icon slightly larger
        ),
        // Only show the label if the item is NOT selected
        if (!isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F7),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(userData: widget.userData),
            const SearchPage(),
            const WishlistPage(),
            ProfilePage(userData: widget.userData),
          ],
        ),
      ),
      // Use CurvedNavigationBar instead of the standard BottomNavigationBar
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: const Color(0xFFFDF7F7), // Must match Scaffold background for transparent effect
        color: Colors.white, // The white pill background
        buttonBackgroundColor: const Color(0xFFE4252A), // The Trending Red floating circle
        height: 65, // Slightly taller to accommodate labels
        animationDuration: const Duration(milliseconds: 350),
        animationCurve: Curves.easeOutCubic,
        onTap: _onItemTapped,
        items: [
          _buildNavItem(Icons.home_filled, 'Home', 0),
          _buildNavItem(Icons.search, 'Search', 1),
          _buildNavItem(Icons.favorite_border, 'Favorites', 2),
          _buildNavItem(Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }
}