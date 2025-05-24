import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_search_app/gif_fullscreen_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gif_search_app/gif_search_page.dart';
import 'package:gif_search_app/giphy_api.dart';
import 'package:gif_search_app/image_loader.dart';

@GenerateMocks([Connectivity])
import 'gif_search_page_test.mocks.dart';

class MockImageLoader extends Mock implements ImageLoader {
  @override
  Widget loadNetworkImage(String url, {
    BoxFit fit = BoxFit.cover,
    Widget? loadingWidget,
  }) {
    return Text('Mock Image');
  }
}
class MockGiphyApi extends Mock implements GiphyApi {
  @override
  Future<List<GifData>> getTrendingGifs({int offset = 0, int limit = 20}) {
    return super.noSuchMethod(
      Invocation.method(#getTrendingGifs, [], {#offset: offset, #limit: limit}),
      returnValue: Future<List<GifData>>.value([]), // Explicit type
      returnValueForMissingStub: Future<List<GifData>>.value([]), // Explicit type
    );
  }

  @override
  Future<List<GifData>> searchGifs(String query, {int offset = 0, int limit = 20}) {
    return super.noSuchMethod(
      Invocation.method(#searchGifs, [query], {#offset: offset, #limit: limit}),
      returnValue: Future<List<GifData>>.value([]), // Explicit type
      returnValueForMissingStub: Future<List<GifData>>.value([]), // Explicit type
    );
  }
}
void main() {
  late MockGiphyApi mockApi;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockApi = MockGiphyApi();
    mockConnectivity = MockConnectivity();

    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);
    
    when(mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => Stream.value([ConnectivityResult.none]));
    

  });
  tearDown(() {
    reset(mockConnectivity);
    reset(mockApi);
  });

  group('GifSearchPage Initialization', () {
    testWidgets('should load trending GIFs on init', (WidgetTester tester) async {
      final mockGifs = [
        GifData(url: 'https://example.com/gif1.gif', width: 100, height: 100),
        GifData(url: 'https://example.com/gif2.gif', width: 200, height: 200),
      ];

      final mockImageLoader = MockImageLoader();
      
      when(mockApi.getTrendingGifs(offset: 0, limit: 20))
          .thenAnswer((_) async => mockGifs);

      await tester.pumpWidget(
        MaterialApp(
          home: GifSearchPage(
            api: mockApi,
            imageLoader: mockImageLoader,
          ),
        ),
      );

      verify(mockApi.getTrendingGifs(offset: 0, limit: 20)).called(1);

      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Mock Image'), findsNWidgets(2));
    });
  });

  group('Search Functionality', () {
    
  testWidgets('search', (WidgetTester tester) async {
    final mockApi = MockGiphyApi();
    
    when(mockApi.getTrendingGifs(offset: 0, limit: 20))
      .thenAnswer((_) async => Future<List<GifData>>.value([]));
    final testGif = GifData(url: 'test.gif', width: 100, height: 100);
    when(mockApi.searchGifs('cats', offset: 0, limit: 20))
        .thenAnswer((_) async => Future<List<GifData>>.value([testGif]));

    await tester.pumpWidget(
      MaterialApp(
        home: GifSearchPage(
          api: mockApi,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'cats');

    await tester.pump();

    await tester.pumpAndSettle(const Duration(seconds: 1));

    verify(mockApi.searchGifs('cats', offset: 0, limit: 20)).called(1);

  });
});

  group('View Mode Toggle', () {
    testWidgets('should switch between grid and list view', (WidgetTester tester) async {
      final mockApi = MockGiphyApi();
    
      when(mockApi.getTrendingGifs(offset: 0, limit: 20))
        .thenAnswer((_) async => Future<List<GifData>>.value([]));
      when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        await tester.pumpWidget(
          MaterialApp(
            home: GifSearchPage(
              api: mockApi,
            ),
          ),
        );


        await tester.tap(find.byKey(Key('toggleViewModeButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(Key('listView')), findsOneWidget);
      });
  });
  testWidgets('should show error message when no internet connection', (WidgetTester tester) async {
  when(mockConnectivity.checkConnectivity())
      .thenAnswer((_) async => [ConnectivityResult.none]);

  await tester.pumpWidget(
    MaterialApp(
      home: GifSearchPage(
        api: mockApi,
        connectivity: mockConnectivity,

      ),
    ),
  );

  await tester.pumpAndSettle(const Duration(seconds: 1));

  expect(find.byKey(Key('noInternetMessage')), findsOneWidget);
  expect(find.text('No internet connection'), findsOneWidget);
});

// gif_fullscreen_page.dart test
  testWidgets('displays GIF in fullscreen with mock image', (WidgetTester tester) async {
    const testUrl = 'https://example.com/test.gif';

    final mockImage = Container(
      key: const Key('mockImage'),
      width: 100,
      height: 100,
      color: Colors.red,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GifFullscreenPage(
          gifUrl: testUrl,
          imageWidget: mockImage,
        ),
      ),
    );

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byKey(const Key('mockImage')), findsOneWidget);
  });
}