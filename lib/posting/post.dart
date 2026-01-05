import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../utils/user_session.dart';
import 'package:http_parser/http_parser.dart';

class PostPage extends StatefulWidget {
  final VoidCallback onPostSuccess;

  const PostPage({
    super.key,
    required this.onPostSuccess,
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _namaBarangController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _deskripsiController = TextEditingController();

  String? _selectedKategori;
  File? _image;
  bool _loading = false;

  final List<String> _kategoriList = [
    'Aksesoris',
    'Alat Tulis',
    'Bahan Masak',
    'Elektronik',
    'Pakaian',
    'Perabotan'
  ];

  final String baseUrl = 'http://10.0.2.2:4000/api/products';

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080, maxHeight: 1080);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _handlePosting() async {
    if (_namaBarangController.text.isEmpty ||
        _lokasiController.text.isEmpty ||
        _selectedKategori == null ||
        _deskripsiController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Input yang diberikan tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = await UserSession.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User belum login'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uri = Uri.parse('http://10.0.2.2:4000/api/products');

      final request = http.MultipartRequest('POST', uri);

      // 🔥 FIELD HARUS SAMA DENGAN CONTROLLER
      request.fields['nameProduct'] = _namaBarangController.text;
      request.fields['location'] = _lokasiController.text;
      request.fields['category'] = _selectedKategori!;
      request.fields['description'] = _deskripsiController.text;
      request.fields['userId'] = userId; // dikonversi BigInt di backend

      // 🔥 FILE HARUS PAKAI KEY "image"
      final ext = _image!.path.split('.').last.toLowerCase();

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _image!.path,
          contentType: MediaType(
            'image',
            ext == 'png' ? 'png' : 'jpeg',
          ),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_namaBarangController.text} berhasil diposting'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _namaBarangController.clear();
          _lokasiController.clear();
          _deskripsiController.clear();
          _selectedKategori = null;
          _image = null;
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onPostSuccess();
        });
      } else {
        debugPrint('STATUS: ${response.statusCode}');
        debugPrint('BODY: $responseBody');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${response.statusCode}: $responseBody'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'FOTO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: _image == null
                      ? const Icon(Icons.add, size: 60, color: Colors.black54)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _namaBarangController,
                decoration: InputDecoration(
                  hintText: 'Nama Barang',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: _lokasiController,
                decoration: InputDecoration(
                  hintText: 'Lokasi',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),

              const SizedBox(height: 15),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  value: _selectedKategori,
                  hint: const Text('Kategori'),
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: _kategoriList
                      .map((kategori) => DropdownMenuItem(
                            value: kategori,
                            child: Text(kategori),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedKategori = v),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Deskripsi',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handlePosting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF827717),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Posting',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
