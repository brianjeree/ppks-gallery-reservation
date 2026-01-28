import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No Scaffold, just scrollable content
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Image
          Container(
            height: 300, // Taller header for "Web" feel
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'assets/foto about/fdrt.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: Text(
                "TENTANG KAMI",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800), // Center content constraint
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sejarah & Inovasi',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pusat Penelitian Kelapa Sawit (PPKS) adalah lembaga penelitian perkebunan tertua di Indonesia. Didirikan pada tahun 1916 oleh AVROS (Algemeene Vereeniging van Rubberplanters ter Oostkust van Sumatra), PPKS telah menjadi pionir dalam riset kelapa sawit dunia.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Visi Kami',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Menjadi lembaga penelitian bertaraf internasional yang mampu memberikan solusi teknologi bagi industri kelapa sawit berkelanjutan.',
                     style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.justify,
                  ),
                   const SizedBox(height: 40),
                   Divider(color: Colors.grey.shade300),
                   const SizedBox(height: 24),
                   Center(
                     child: Text(
                       'Established 1916',
                       style: GoogleFonts.playfairDisplay(
                         fontSize: 18,
                         fontStyle: FontStyle.italic,
                         color: Colors.grey,
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
