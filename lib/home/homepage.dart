import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../notification/notif.dart';
import '../profile/profile_user.dart';
import '../posting/post.dart';
import '../services/api_service.dart';
import 'package:app_unigive/utils/user_session.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0, end: 0.5).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Widget> _buildPages() {
    return [
      const BerandaPage(),
      PostPage(
        onPostSuccess: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    return Scaffold(
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bg1.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          pages[_selectedIndex],
          if (_selectedIndex == 0)
            Positioned(
              top: 40,
              left: 20,
              child: Image.asset('assets/uniLogo.png', height: 60),
            ),
          if (_selectedIndex == 0)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.notifications_none, size: 32),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationPage(),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

/* ================= BERANDA ================= */

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  List<dynamic> _products = [];
  bool _loading = true;

  final List<Map<String, dynamic>> categories = [
    {'name': 'Aksesoris', 'icon': Icons.shopping_bag},
    {'name': 'Alat Tulis', 'icon': Icons.edit},
    {'name': 'Bahan Masak', 'icon': Icons.restaurant},
    {'name': 'Elektronik', 'icon': Icons.laptop},
    {'name': 'Pakaian', 'icon': Icons.checkroom},
    {'name': 'Perabotan', 'icon': Icons.home},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final result = await ApiService.getProducts();
      setState(() {
        _products = result;
        _loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _loading = false);
    }
  }

  List<dynamic> getFilteredProducts() {
    return _products.where((product) {
      final name =
          product['nameProduct']?.toString().toLowerCase() ?? '';
      final seller =
          product['user']?['name']?.toString().toLowerCase() ?? '';
      final location =
          product['location']?.toString().toLowerCase() ?? '';
      final category =
          product['category']?.toString() ?? '';

      final matchSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          seller.contains(_searchQuery.toLowerCase()) ||
          location.contains(_searchQuery.toLowerCase());

      final matchCategory =
          _selectedCategory == 'Semua' ||
              category == _selectedCategory;

      return matchSearch && matchCategory;
    }).toList();
  }

  // 🔹 Fungsi untuk mengajukan barang
  Future<void> _submitProductRequest(dynamic productId, String productName) async {
    try {
      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get user ID dari session
      final userId = await UserSession.getUserId();
      
      if (userId == null) {
        Navigator.pop(context); // Close loading
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

      // Hit API GET untuk WhatsApp redirect
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4000/api/products/$productId/whatsapp'),
      );

      Navigator.pop(context); // Close loading

      print('WhatsApp API Response status: ${response.statusCode}');
      print('WhatsApp API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          // Ambil URL WhatsApp dari response
          final String whatsappUrl = data['data']['whatsappUrl'] ?? '';
          
          if (whatsappUrl.isNotEmpty) {
            // Buka WhatsApp
            final Uri uri = Uri.parse(whatsappUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membuka WhatsApp untuk "$productName"'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tidak dapat membuka WhatsApp'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL WhatsApp tidak ditemukan'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Gagal mengajukan permintaan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengajukan permintaan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading jika masih ada
      print('Error submitting product request: $e');
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

  // 🔹 Fungsi untuk menampilkan dialog konfirmasi
  void _showConfirmationDialog(dynamic productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF827717)),
            SizedBox(width: 8),
            Text('Konfirmasi Pengajuan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin mengajukan permintaan untuk:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Color(0xFF827717)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Anda akan diarahkan ke WhatsApp untuk menghubungi pemilik barang.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitProductRequest(productId, productName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF827717),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Ajukan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = getFilteredProducts();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final name =
                        index == 0 ? 'Semua' : categories[index - 1]['name'];
                    final icon =
                        index == 0 ? Icons.apps : categories[index - 1]['icon'];
                    final selected = _selectedCategory == name;

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = name),
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: selected
                                  ? Colors.green
                                  : Colors.grey[300],
                              child: Icon(icon,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            const SizedBox(height: 6),
                            Text(name,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Siap Untuk Di Donasikan!!!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 20),




              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (filteredProducts.isEmpty)
                const Center(child: Text('Produk tidak ditemukan'))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(
                      context,
                      filteredProducts[index] as Map<String, dynamic>
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final String name = product['nameProduct'] ?? '-';
    final String category = product['category'] ?? '-';
    final String location = product['location'] ?? '-';
    final String seller = product['user']?['name'] ?? '-';
    final String imageUrl =
        'http://10.0.2.2:4000${product['urlGambar']}';
    final dynamic productId = product['id'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🖼 GAMBAR
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.image,
                        size: 60, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
          ),

          /// 📄 INFO
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🏷 KATEGORI
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                /// 📦 NAMA PRODUK
                Text(
                  name,
                  style:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                /// 👤 SELLER
                Text(
                  seller,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),

                const SizedBox(height: 4),

                /// 📍 LOKASI
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: Colors.red),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        location,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// 🔘 BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(productId, name);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF827717),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Ajukan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
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