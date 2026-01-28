import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UnifiedReservationScreen extends StatefulWidget {
  const UnifiedReservationScreen({super.key});

  @override
  State<UnifiedReservationScreen> createState() => _UnifiedReservationScreenState();
}

class _UnifiedReservationScreenState extends State<UnifiedReservationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _agencyController = TextEditingController();
  final _countController = TextEditingController();
  final _purposeController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedSession; // Values: 'Sesi Pagi 09:00-11:00', 'Sesi Siang 13:00-15:00'
  
  bool _isFormLoading = false;

  // Search Controllers
  final _searchNameController = TextEditingController();
  String _searchName = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _agencyController.dispose();
    _countController.dispose();
    _purposeController.dispose();
    _dateController.dispose();
    _searchNameController.dispose();
    super.dispose();
  }

  // --- FORM LOGIC ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitReservation() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSession == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih sesi kunjungan')));
        return;
      }
      setState(() { _isFormLoading = true; });
      try {
        await FirebaseFirestore.instance.collection('reservations').add({
          'date': _selectedDate,
          'session': _selectedSession,
          'name': _nameController.text.trim(),
          'agency': _agencyController.text.trim(),
          'visitor_count': int.parse(_countController.text),
          'purpose': _purposeController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservasi Berhasil Dikirim!')));
          _formKey.currentState!.reset();
          _nameController.clear(); _agencyController.clear(); _countController.clear(); _purposeController.clear(); _dateController.clear();
          setState(() { _selectedDate = null; _selectedSession = null; });
          _tabController.animateTo(1);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() { _isFormLoading = false; });
      }
    }
  }

  // --- SEARCH LOGIC ---
  void _searchReservation() {
    setState(() {
      _searchName = _searchNameController.text.trim();
      _isSearching = true;
      FocusScope.of(context).unfocus();
    });
  }

  // --- UI BUILDING BLOCKS ---

  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      filled: true,
      fillColor: Colors.grey[50], // Very light grey
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

  Widget _buildSessionCard(String title, String time, IconData icon, String value) {
    final bool isSelected = _selectedSession == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSession = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.green.shade700 : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green.shade800 : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white, // Clean base
      body: isDesktop
          ? Row(
              children: [
                // Left Panel (40%) - Image
                Expanded(
                  flex: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                       Image.network(
                        "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=1000", // Fixed Image
                        fit: BoxFit.cover,
                      ),
                      Container(color: Colors.black.withOpacity(0.5)),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Jadwalkan\nKunjungan Anda",
                                style: GoogleFonts.poppins(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Nikmati pengalaman edukasi seputar kelapa sawit langsung dari sumbernya.",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Panel (60%) - Form
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      _buildRightPanelContent(),
                      // AppBar Legibility Gradient for Right Panel
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.green.shade900.withOpacity(0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column( // Mobile Layout
              children: [
                // Header Image (30%)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: double.infinity,
                  child: Stack(
                     fit: StackFit.expand,
                     children: [
                        Image.network(
                        "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=1000", // Fixed Image (Kebun Sawit)
                        fit: BoxFit.cover,
                      ),
                      Container(color: Colors.black.withOpacity(0.5)),
                       Center(
                         child: Text(
                           "Jadwalkan Kunjungan",
                           style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                         ),
                       )
                     ],
                  ),
                ),
                // Body (Rounded Top)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    margin: const EdgeInsets.only(top: -24), // Overlap effect
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      child: _buildRightPanelContent(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRightPanelContent() {
    return Column(
      children: [
        // Custom Tab Bar (Clean)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 0), // Increased Top Padding to clear AppBar/Gradient
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
              ),
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(vertical: 12),
              tabs: [
                Text("Buat Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text("Cek Status", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFormTab(),
              _buildStatusTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Max Form Width
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Detail Reservasi", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Date Picker
                TextFormField(
                  controller: _dateController,
                  decoration: _modernInputDecoration("Tanggal Kunjungan", Icons.calendar_today_outlined),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (v) => v!.isEmpty ? 'Mohon pilih tanggal' : null,
                ),
                const SizedBox(height: 24),

                // Custom Session Selection
                Text("Pilih Sesi", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSessionCard("Sesi Pagi", "09:00 - 11:00", Icons.wb_sunny_outlined, 'Sesi Pagi 09:00-11:00'),
                    const SizedBox(width: 16),
                    _buildSessionCard("Sesi Siang", "13:00 - 15:00", Icons.cloud_outlined, 'Sesi Siang 13:00-15:00'),
                  ],
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: _modernInputDecoration("Nama Lengkap", Icons.person_outline),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Agency
                TextFormField(
                  controller: _agencyController,
                  decoration: _modernInputDecoration("Asal Instansi", Icons.business_outlined),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Count
                TextFormField(
                  controller: _countController,
                  decoration: _modernInputDecoration("Jumlah Pengunjung", Icons.people_outline),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Purpose
                TextFormField(
                  controller: _purposeController,
                  decoration: _modernInputDecoration("Tujuan Kunjungan", Icons.edit_note),
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isFormLoading ? null : _submitReservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // For gradient
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
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
                        child: _isFormLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "KONFIRMASI RESERVASI",
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
                 const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab() {
     return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text("Cek Status Tiket", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
               const SizedBox(height: 24),
              TextField(
                controller: _searchNameController,
                decoration: _modernInputDecoration("Cari Nama Pendaftar", Icons.search),
                onSubmitted: (_) => _searchReservation(),
              ),
              const SizedBox(height: 24),
              if (_isSearching && _searchName.isNotEmpty)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reservations')
                      .where('name', isEqualTo: _searchName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Data tidak ditemukan', style: TextStyle(color: Colors.grey)));
                    }

                    final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                    docs.sort((a, b) {
                      final aTime = (a.data() as Map)['created_at'] as Timestamp?;
                      final bTime = (b.data() as Map)['created_at'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime);
                    });

                    return Column(
                      children: docs.map((doc) => _buildTicketCard(doc)).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(DocumentSnapshot doc) {
    // Same card logic, slightly clearer styling
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    Color color = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(), 
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)
                  ),
                ),
                Text(
                  data['created_at'] != null 
                    ? DateFormat('dd MMM yyyy').format((data['created_at'] as Timestamp).toDate())
                    : '-',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.grey[100],
                child: Icon(Icons.person, color: Colors.grey[600]),
              ),
              title: Text(data['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text("${data['agency']} • ${data['visitor_count']} Orang", style: GoogleFonts.poppins(fontSize: 12)),
              trailing: status == 'approved' 
                ? IconButton(
                    icon: const Icon(Icons.qr_code, size: 32), 
                    onPressed: () => _showQRCode(doc.id),
                    color: Colors.black,
                  ) 
                : null,
            ),
             if (status == 'approved')
               Text("Ketuk QR untuk memperbesar", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  void _showQRCode(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(data: code, size: 200),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
