import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

class VisitCheckScreen extends StatefulWidget {
  const VisitCheckScreen({super.key});

  @override
  State<VisitCheckScreen> createState() => _VisitCheckScreenState();
}

class _VisitCheckScreenState extends State<VisitCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _agencyController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  String? _loadingStatus;
  bool get _isLoading => _loadingStatus != null;
  DocumentSnapshot? _selectedReservation;
  List<DocumentSnapshot> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _agencyController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await FirebaseFirestore.instance
          .collection('reservations')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .where('status', isEqualTo: 'approved')
          .limit(5)
          .get();

      setState(() {
        _suggestions = results.docs;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _submitVisit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan berikan tanda tangan')),
      );
      return;
    }

    setState(() => _loadingStatus = 'Mempersiapkan...');

    try {
      // 1. Ensure user is authenticated (Storage often requires auth)
      if (FirebaseAuth.instance.currentUser == null) {
        setState(() => _loadingStatus = 'Authenticating...');
        await FirebaseAuth.instance.signInAnonymously();
      }

      setState(() => _loadingStatus = 'Mengolah tanda tangan...');

      // 2. Export signature as image
      final Uint8List? signatureImage = await _signatureController.toPngBytes();
      if (signatureImage == null)
        throw Exception('Gagal memproses tanda tangan.');

      setState(() => _loadingStatus = 'Menghubungkan ke Storage...');

      // 3. Upload signature to Firebase Storage
      final String fileName =
          'signatures/${DateTime.now().millisecondsSinceEpoch}.png';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = storageRef.putData(
        signatureImage,
        SettableMetadata(contentType: 'image/png'),
      );

      // Monitor progress
      final StreamSubscription snapshotSubscription = uploadTask.snapshotEvents
          .listen(
            (TaskSnapshot snapshot) {
              if (mounted) {
                final progress =
                    (snapshot.bytesTransferred / snapshot.totalBytes * 100)
                        .round();
                setState(() => _loadingStatus = 'Mengunggah: $progress%');
              }
            },
            onError: (e) {
              debugPrint('Upload error listener: $e');
            },
          );

      try {
        final TaskSnapshot taskSnapshot = await uploadTask.timeout(
          const Duration(seconds: 30),
        );
        await snapshotSubscription.cancel();

        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        setState(() => _loadingStatus = 'Menyimpan data kunjungan...');

        // 4. Save visit data to Firestore
        await FirebaseFirestore.instance.collection('visits').add({
          'name': _nameController.text.trim(),
          'agency': _agencyController.text.trim(),
          'notes': _notesController.text.trim(),
          'signature_url': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'reservation_id': _selectedReservation?.id,
        });

        if (mounted) {
          setState(() => _loadingStatus = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunjungan berhasil dicatat!')),
          );
          _resetForm();
        }
      } catch (e) {
        await snapshotSubscription.cancel();
        rethrow;
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _loadingStatus = null);
        String errorMsg = 'Firebase Error: ${e.message}';
        if (e.code == 'unauthorized')
          errorMsg = 'Akses Storage tidak diizinkan.';
        if (e.code == 'canceled') errorMsg = 'Upload dibatalkan.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() => _loadingStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload Timeout. Periksa koneksi internet Anda.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _agencyController.clear();
    _notesController.clear();
    _searchController.clear();
    _signatureController.clear();
    setState(() {
      _selectedReservation = null;
      _suggestions = [];
      _loadingStatus = null;
    });
  }

  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      filled: true,
      fillColor: Colors.grey[50],
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Buku Tamu Digital',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Visit Check & Signature",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Silakan isi data kunjungan Anda di bawah ini.",
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Search Reservation
              TextFormField(
                controller: _searchController,
                decoration: _modernInputDecoration(
                  "Cari Reservasi (Opsional)",
                  Icons.search,
                ),
                onChanged: _onSearchChanged,
              ),
              if (_isSearching) const LinearProgressIndicator(),
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final doc = _suggestions[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(
                          "${data['agency']} - ${data['session']}",
                        ),
                        onTap: () {
                          setState(() {
                            _selectedReservation = doc;
                            _nameController.text = data['name'] ?? '';
                            _agencyController.text = data['agency'] ?? '';
                            _suggestions =
                                []; // Clear suggestions after selection
                            _searchController.text =
                                data['name'] ??
                                ''; // Set search text to selected name
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: _modernInputDecoration(
                  "Nama Lengkap",
                  Icons.person_outline,
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _agencyController,
                decoration: _modernInputDecoration(
                  "Asal Instansi",
                  Icons.business_outlined,
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: _modernInputDecoration(
                  "Catatan / Keperluan",
                  Icons.note_alt_outlined,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              Text(
                "Tanda Tangan Digital",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Signature(
                      controller: _signatureController,
                      height: 200,
                      backgroundColor: Colors.transparent,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _signatureController.clear(),
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text("Hapus"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVisit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _loadingStatus!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "SIMPAN KUNJUNGAN",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
