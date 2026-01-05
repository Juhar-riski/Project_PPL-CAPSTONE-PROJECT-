import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:4000/api';

  static Future<List<dynamic>> getProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json['data'];
    } else {
      throw Exception('Gagal mengambil produk');
    }
  }
}
