import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestAssistant {
  static Future<dynamic> getRequest(String url) async {
    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      String jSonData = response.body;
      var decodeData = jsonDecode(jSonData);
      return decodeData;
    } else {
      print(response.statusCode);
      return "failed";
    }
  }
}
