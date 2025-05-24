import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gif_search_app/giphy_api.dart';

void main() {
  group('GiphyApi', () {
    late GiphyApi api;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient((request) async {
        if (request.url.toString().contains('trending')) {
          return http.Response('''
            {
              "data": [
                {
                  "images": {
                    "fixed_width": {
                      "url": "https://giphy.com/trending1.gif",
                      "width": "200",
                      "height": "100"
                    }
                  }
                }
              ]
            }
          ''', 200);
        } else if (request.url.toString().contains('search')) {
          return http.Response('''
            {
              "data": [
                {
                  "images": {
                    "fixed_width": {
                      "url": "https://giphy.com/search1.gif",
                      "width": "300",
                      "height": "150"
                    }
                  }
                }
              ]
            }
          ''', 200);
        }
        return http.Response('', 404);
      });
      api = GiphyApi(client: mockClient);
    });

    test('getTrendingGifs returns list of GifData', () async {
      final gifs = await api.getTrendingGifs();
      expect(gifs, isNotEmpty);
      expect(gifs[0].url, 'https://giphy.com/trending1.gif');
      expect(gifs[0].width, 200);
      expect(gifs[0].height, 100);
    });

    test('searchGifs returns list of GifData', () async {
      final gifs = await api.searchGifs('cats');
      expect(gifs, isNotEmpty);
      expect(gifs[0].url, 'https://giphy.com/search1.gif');
      expect(gifs[0].width, 300);
      expect(gifs[0].height, 150);
    });

    test('throws exception when API fails', () async {
      final failingApi = GiphyApi(client: MockClient((_) async => http.Response('', 500)));
      expect(() => failingApi.getTrendingGifs(), throwsException);
      expect(() => failingApi.searchGifs('cats'), throwsException);
    });
  });

  group('GifData', () {
    test('fromJson handles invalid width/height', () {
      final json = {
        'images': {
          'fixed_width': {
            'url': 'test.gif',
            'width': 'invalid',
            'height': 'invalid'
          }
        }
      };
      final gif = GifData.fromJson(json);
      expect(gif.width, 1);
      expect(gif.height, 1);
    });
  });

  test('handles empty response data', () async {
    final emptyClient = MockClient((_) async => http.Response('{"data": []}', 200));
    final api = GiphyApi(client: emptyClient);
    
    final trending = await api.getTrendingGifs();
    expect(trending, isEmpty);
    
    final search = await api.searchGifs('cats');
    expect(search, isEmpty);
  });
}