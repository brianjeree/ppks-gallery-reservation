import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _backgroundImages = [
    'assets/foto homescreen/kebun sawit.png',
    'assets/foto homescreen/kebun sawit 2.png',
    'assets/foto homescreen/pohon sawit.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _currentPage++;
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(seconds: 2), // Slow, elegant transition
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Layer 1: Carousel Background
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable manual swipe for background
            // itemCount: null, // Infinite
            itemBuilder: (context, index) {
              return Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_backgroundImages[index % _backgroundImages.length]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          
          // Layer 2: Overlay
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // Layer 3: Hero Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forest, color: Colors.white70, size: 80),
                const SizedBox(height: 24),
                Text(
                  'GALERI PPKS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'HERITAGE & INNOVATION', 
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 3.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
