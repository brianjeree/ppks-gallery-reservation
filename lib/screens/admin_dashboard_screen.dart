import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'qr_scan_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _updateStatus(BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(docId)
          .update({'status': newStatus});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    return 'Unknown Date';
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> data, String docId, String status) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Detail Pengunjung", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, "Nama", data['name']),
              _buildDetailRow(Icons.business, "Instansi", data['agency']),
              _buildDetailRow(Icons.people, "Jumlah", "${data['visitor_count']} Orang"),
              _buildDetailRow(Icons.calendar_today, "Tanggal", _formatDate(data['date'])),
              _buildDetailRow(Icons.schedule, "Sesi", data['session']),
              _buildDetailRow(Icons.notes, "Tujuan", data['purpose']),
              const SizedBox(height: 24),
              if (status == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _updateStatus(context, docId, 'rejected');
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text("TOLAK"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _updateStatus(context, docId, 'approved');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("TERIMA"),
                    ),
                  ],
                ),
               if (status != 'pending')
                 Align(
                   alignment: Alignment.centerRight,
                   child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("TUTUP")),
                 )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(value ?? '-', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          bottom: TabBar(
            indicatorColor: Colors.green.shade800,
            labelColor: Colors.green.shade800,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Menunggu Persetujuan"),
              Tab(text: "Riwayat Kunjungan"),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Data Pengunjung", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text("Kelola daftar kunjungan Galeri PPKS", style: GoogleFonts.poppins(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reservations')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Belum ada data'));

                  final allDocs = snapshot.data!.docs;
                  final pendingDocs = allDocs.filter((doc) => (doc.data() as Map)['status'] == 'pending').toList();
                  final historyDocs = allDocs.filter((doc) => (doc.data() as Map)['status'] != 'pending').toList();

                  return TabBarView(
                    children: [
                      _buildList(context, pendingDocs, true),
                      _buildList(context, historyDocs, false),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScanScreen())),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text("Scan Tiket"),
          backgroundColor: Colors.green.shade800,
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<QueryDocumentSnapshot> docs, bool isPending) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Tidak ada data", style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () => _showDetailDialog(context, data, doc.id, status),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isPending ? Colors.orange.shade50 : Colors.grey.shade100,
                    child: Icon(
                      isPending ? Icons.pending_actions : (status == 'approved' ? Icons.check : Icons.close),
                      color: isPending ? Colors.orange : (status == 'approved' ? Colors.green : Colors.red),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'No Name',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                         Text(
                          "${data['agency']} • ${data['visitor_count']} Orang",
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    ElevatedButton(
                      onPressed: () => _showDetailDialog(context, data, doc.id, status),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Review"),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension ListFilter<E> on List<E> {
  List<E> filter(bool Function(E) test) => where(test).toList();
}
