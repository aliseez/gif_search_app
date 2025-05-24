import 'dart:convert';
import 'package:http/http.dart' as http;
class GifData {
  final String url;
  final int width;
  final int height;

  GifData({required this.url, required this.width, required this.height});

  factory GifData.fromJson(Map<String, dynamic> json) {
    final image = json['images']['fixed_width'];
    return GifData(
      url: image['url'],
      width: int.tryParse(image['width']) ?? 1,
      height: int.tryParse(image['height']) ?? 1,
    );
  }
}

class GiphyApi {
  final String apiKey;
  final http.Client client;
  GiphyApi({
    required this.client,
    this.apiKey = 'hynfPtXgNxX6hK1Jk7uFJgBGuU9rXqrj',
  });
  Future<List<GifData>> searchGifs(String query, {int offset = 0, int limit = 10}) async {
    final url = Uri.parse(
      'https://api.giphy.com/v1/gifs/search?api_key=$apiKey&q=$query&limit=$limit&offset=$offset&rating=g&lang=en&bundle=messaging_non_clips',
    );
    

    final response = await client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List gifs = data['data'];
      return gifs.map<GifData>((gif) => GifData.fromJson(gif)).toList();
    } else {
      throw Exception('Neizdevās ielādēt GIF');
    }
  }

  Future<List<GifData>> getTrendingGifs({int offset = 0, int limit = 10}) async {
    final url = Uri.parse(
      'https://api.giphy.com/v1/gifs/trending?api_key=$apiKey&limit=$limit&offset=$offset&rating=g&bundle=messaging_non_clips',
    );

    final response = await client.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List gifs = data['data'];
      return gifs.map<GifData>((gif) => GifData.fromJson(gif)).toList();
    } else {
      throw Exception('Neizdevās ielādēt trending GIFs');
    }
  }
}