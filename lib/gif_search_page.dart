import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'giphy_api.dart';
import 'gif_fullscreen_page.dart';
import 'image_loader.dart';
class GifSearchPage extends StatefulWidget {
  final GiphyApi? api;
  final http.Client? httpClient; // Add httpClient parameter
  final ImageLoader? imageLoader;
  final Connectivity? connectivity;
  const GifSearchPage({super.key, this.api, this.httpClient, this.imageLoader, this.connectivity,});

  @override
  GifSearchPageState createState() => GifSearchPageState();
}

class GifSearchPageState extends State<GifSearchPage> {

  static const int defaultLimit = 20;
  static const Duration debounceDuration = Duration(milliseconds: 300);

  late final GiphyApi api;
  late final ImageLoader imageLoader; 
  late final Connectivity connectivity;

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<GifData> gifs = [];
  String currentQuery = '';
  int offset = 0;
  bool hasMore = true;

  bool isGridView = true;
  bool isLoading = false;
  String? errorMessage;

  Timer? _debounce;


  @override
  void initState() {
    super.initState();
    api = widget.api ?? GiphyApi(client: widget.httpClient ?? http.Client());
    imageLoader = widget.imageLoader ?? ImageLoader();
    connectivity = widget.connectivity ?? Connectivity();
    _checkInitialConnectivity();
    _initConnectivity();

    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await connectivity.checkConnectivity();
    if (result == ConnectivityResult.none) {
      setState(() {
        errorMessage = 'No internet connection';
      });
    } else {
      await loadTrending();
    }
  }

  Future<void> _initConnectivity() async {
    connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && errorMessage != null) {
        setState(() {
          errorMessage = 'No internet connection';
        });
        _loadInitialData();
      }
      else{
        setState(() {
        errorMessage = 'No internet connection';
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (controller.text.isEmpty) {
      await loadTrending();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () {
      if (mounted && controller.text == query) {
        search(query);
      }
    });
  }

  void _onScroll() {
    if (scrollController.position.pixels >= 
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  void _toggleViewMode() {
    setState(() {
      isGridView = !isGridView;
    });
  }

  void _openFullscreen(String gifUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GifFullscreenPage(gifUrl: gifUrl),
      ),
    );
  }

  Future<void> loadTrending() async {
    if (!mounted) return;
    
    setState(() {
      gifs.clear();
      offset = 0;
      hasMore = true;
      currentQuery = '';
      errorMessage = null;
    });

    await loadMore();
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      print('7. Preparing API call with query: "$currentQuery"');
      List<GifData> results;
      if (currentQuery.isEmpty) {
        results = await api.getTrendingGifs(offset: offset, limit: defaultLimit);
      } else {
        results = await api.searchGifs(currentQuery, offset: offset, limit: defaultLimit);
      }

      if (!mounted) return;
      setState(() {
        gifs.addAll(results);
        offset += defaultLimit;
        hasMore = results.length == defaultLimit;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      setState(() {
        errorMessage = 'Neizdevās ielādēt GIF. Pārbaudi savienojumu.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> search(String query) async {
    
    setState(() {
      currentQuery = query;
      gifs.clear();
      offset = 0;
      hasMore = true;
      errorMessage = null;
    });

    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == [ConnectivityResult.none]) {

      if (!mounted) return;
      setState(() {
        errorMessage = 'No internet connection';
      });
      return;
    }

    if (!mounted) return;
    
    await loadMore();
  }


  Widget _buildGridView() {

    return GridView.builder(

      key: Key('gridView'),
      controller: scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: gifs.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < gifs.length) {
          final gif = gifs[index];
          return GestureDetector(
            onTap: () => _openFullscreen(gif.url),
            child: imageLoader.loadNetworkImage(gif.url),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _buildListView() {

    return ListView.builder(

      key: Key('listView'),
      controller: scrollController,
      itemCount: gifs.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < gifs.length) {
          final gif = gifs[index];
          final screenWidth = MediaQuery.of(context).size.width;
          final height = screenWidth / (gif.width / gif.height);

          return GestureDetector(
            onTap: () => _openFullscreen(gif.url),
            child: Container(
              width: double.infinity,
              height: height,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: imageLoader.loadNetworkImage(
                gif.url,
                fit: BoxFit.contain,
                loadingWidget: const Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _buildContent() {

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (gifs.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (gifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              currentQuery.isEmpty 
                ? 'No trending GIFs found' 
                : 'No results for "$currentQuery"',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return isGridView ? _buildGridView() : _buildListView();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('GIF Search'),
        actions: [
          IconButton(
            key: Key('toggleViewModeButton'),
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: _toggleViewMode,
            tooltip: isGridView ? 'Switch to List' : 'Switch to Grid',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              
              controller: controller,
              onChanged: (query) {
                print('Text changed: $query');
                _onSearchChanged(query);
              },
              onSubmitted: (query) {
                print('Submitted: $query');
                search(query);
              },
              decoration: InputDecoration(
                labelText: 'Search GIF',
                suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        _onSearchChanged('');
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => search(controller.text),
                    ),
              ),
            ),
          ),
          Expanded(
            child: errorMessage != null
                  ? Center(
                    key: Key('noInternetMessage'),
                    child: Text(errorMessage!)) 
                  : _buildContent(),
          ),
        ],
      ),
    );
  }
}