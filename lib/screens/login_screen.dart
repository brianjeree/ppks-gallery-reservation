import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password harus diisi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan login.';
      if (e.code == 'user-not-found') {
        message = 'Pengguna tidak ditemukan.';
      } else if (e.code == 'wrong-password') {
        message = 'Password salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'invalid-credential') {
        message = 'Kredensial tidak valid.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Styles reused from UnifiedReservationScreen
  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("KEMBALI KE BERANDA", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Image Panel (40%)
        Expanded(
          flex: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/home_images/kebun sawit 2.png',
                fit: BoxFit.cover,
              ),
              Container(color: Colors.black.withOpacity(0.6)),
              Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.greenAccent),
                    const SizedBox(height: 24),
                    Text(
                      "Admin Portal",
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Kelola reservasi, verifikasi tiket, dan pantau kunjungan Galeri PPKS dengan mudah.",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Right Form Panel (60%)
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildLoginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Background Image
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          width: double.infinity,
          child: Image.asset(
            'assets/home_images/kebun sawit 2.png',
            fit: BoxFit.cover,
          ),
        ),
        Container(color: Colors.black.withOpacity(0.5)),
        
        // Content
        Column(
          children: [
             SizedBox(height: MediaQuery.of(context).size.height * 0.15),
             Text(
               "Admin Portal",
               style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
             ),
             const SizedBox(height: 40),
             Expanded(
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(32),
                 decoration: const BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                 ),
                 child: SingleChildScrollView(
                   child: _buildLoginForm(),
                 ),
               ),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Selamat Datang Kembali",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade900),
        ),
        const SizedBox(height: 8),
        Text(
          "Silakan login untuk mengakses dashboard.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 48),

        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _modernInputDecoration("Email Address", Icons.email_outlined),
        ),
        const SizedBox(height: 24),

        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: _isObscure,
          decoration: _modernInputDecoration("Password", Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade800, Colors.green.shade600],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Text(
                        "MASUK DASHBOARD",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
