import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'unified_reservation_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = const [
    HomeScreen(),
    UnifiedReservationScreen(),
    AboutScreen(),
    ContactScreen(),
  ];

  final List<String> _menuItems = ["HOME", "RESERVATION", "ABOUT", "CONTACT"];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMenuSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Slide Animation
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check Screen Width
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      extendBodyBehindAppBar: true, // Transparent AppBar effect
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            "GALERI PPKS",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              shadows: [
                 Shadow(offset: const Offset(0, 2), blurRadius: 4, color: Colors.black.withOpacity(0.5)),
              ],
            ),
          ),
        ),
        actions: [
          if (isDesktop)
            // Desktop Menu (Row of Buttons)
            Row(
              children: List.generate(_menuItems.length, (index) {
                final bool isActive = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextButton(
                    onPressed: () => _onMenuSelected(index),
                    style: TextButton.styleFrom(
                      foregroundColor: isActive ? Colors.white : Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        decoration: isActive ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: Colors.white,
                        decorationThickness: 2,
                      ),
                    ),
                    child: Text(_menuItems[index]),
                  ),
                );
              }),
            )
          else
            // Mobile Menu (Dropdown/Popup)
            PopupMenuButton<int>(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: _onMenuSelected,
              itemBuilder: (context) {
                return List.generate(_menuItems.length, (index) {
                  return PopupMenuItem(
                    value: index,
                    child: Text(
                      _menuItems[index],
                      style: GoogleFonts.poppins(
                        color: _currentIndex == index ? Colors.green : Colors.black87,
                        fontWeight: _currentIndex == index ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                });
              },
            ),
          const SizedBox(width: 24),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures for "Web" feel
        children: _screens,
      ),
    );
  }
}
