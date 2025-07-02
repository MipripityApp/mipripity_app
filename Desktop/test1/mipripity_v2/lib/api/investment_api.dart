import 'package:http/http.dart' as http;
import '../invest_screen.dart';
import 'dart:convert';

class InvestmentApi {
  static Future<List<Investment>> fetchInvestments() async {
    const url = 'https://mipripity-api-1.onrender.com/investments';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((investment) => Investment.fromJson(investment))
          .toList();
    } else {
      throw Exception('Failed to load investments');
    }
  }
}
