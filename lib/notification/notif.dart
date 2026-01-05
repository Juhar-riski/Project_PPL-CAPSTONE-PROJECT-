import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_unigive/utils/user_session.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );
    _animationController!.forward();

    // Load notifications
    _loadNotifications();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // 🔹 Load notifications from API
  Future<void> _loadNotifications() async {
    try {
      // Get user ID from session
      userId = await UserSession.getUserId();
      
      if (userId == null) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID tidak ditemukan. Silakan login ulang.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:4000/api/notifications/$userId'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            notifications = List<Map<String, dynamic>>.from(
              data['data'].map((notif) => {
                'id': notif['id'], // Tetap sebagai tipe aslinya
                'userId': notif['userId'],
                'productId': notif['productId'],
                'isRead': notif['isRead'],
                'createdAt': notif['createdAt'],
                'updatedAt': notif['updatedAt'],
                'productName': notif['product']?['nameProduct'] ?? 'Nama Barang',
              })
            );
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat notifikasi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔹 Mark notification as read (Setuju)
  // PUT /api/notifications/:id/read
  Future<void> _markAsRead(dynamic notificationId, int index) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:4000/api/notifications/$notificationId/read'),
      );

      print('Mark as read response: ${response.statusCode}');
      print('Mark as read body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          setState(() {
            notifications[index]['isRead'] = true;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permintaan disetujui'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Gagal menyetujui permintaan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyetujui permintaan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error marking as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔹 Delete notification (Tidak)
  // DELETE /api/notifications/:id/delete
  Future<void> _deleteNotification(dynamic notificationId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:4000/api/notifications/$notificationId/delete'),
      );

      print('Delete response: ${response.statusCode}');
      print('Delete body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          setState(() {
            notifications.removeAt(index);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permintaan ditolak'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Gagal menolak permintaan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menolak permintaan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation!,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        // Refresh button
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                            });
                            _loadNotifications();
                          },
                        ),
                      ],
                    ),
                  ),
                  // List Notifikasi
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada notifikasi',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadNotifications,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notif = notifications[index];
                                    return _buildNotificationItem(notif, index);
                                  },
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

  Widget _buildNotificationItem(Map<String, dynamic> notif, int index) {
    final bool isRead = notif['isRead'] ?? false;
    final String productName = notif['productName'] ?? 'Nama Barang';
    final dynamic notificationId = notif['id']; // Ubah dari int ke dynamic

    // Generate message based on isRead status
    final String message = isRead
        ? '"$productName" Sudah Dipinang nihhh!!!! Terima Kasih Atas Kebaikannya'
        : '"$productName" Milik Anda Ada Yang Meminang nihh, Setuju Di Berikan?!!';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title dengan red dot (hanya tampil jika belum dibaca)
          if (!isRead)
            Row(
              children: [
                // Red dot indicator untuk unread
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                // Title
                const Text(
                  'Permintaan Barang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            )
          else
            // Jika sudah dibaca, tampilkan title di tengah tanpa red dot
            const Center(
              child: Text(
                'Permintaan Barang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          const SizedBox(height: 8),
          
          // Message - di tengah jika sudah dibaca
          if (!isRead)
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            )
          else
            Center(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Action Buttons - hanya tampil jika belum dibaca
          if (!isRead) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Tidak
                SizedBox(
                  width: 90,
                  child: ElevatedButton(
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi'),
                          content: const Text('Apakah Anda yakin ingin menolak permintaan ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteNotification(notificationId, index);
                              },
                              child: const Text(
                                'Tolak',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 130, 23, 28),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tidak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Setuju
                SizedBox(
                  width: 90,
                  child: ElevatedButton(
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi'),
                          content: const Text('Apakah Anda yakin ingin menyetujui permintaan ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _markAsRead(notificationId, index);
                              },
                              child: const Text(
                                'Setuju',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF827717),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Setuju',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}