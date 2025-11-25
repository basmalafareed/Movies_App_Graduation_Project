import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../providers/search_provider.dart';
import '../../data/models/movie_model.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _controller = TextEditingController();
  String _currentText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch([String? value]) {
    context.read<SearchProvider>().search(value ?? _controller.text);
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _currentText = '');
    context.read<SearchProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearch,
                  onChanged: (value) => setState(() => _currentText = value),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(0.6),
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/images/search_icon.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _currentText.isNotEmpty ? Icons.close : Icons.search,
                        color: Colors.white70,
                      ),
                      onPressed: _currentText.isNotEmpty
                          ? _clearQuery
                          : _onSearch,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!provider.hasSearched) {
                    return _buildIllustration();
                  }

                  if (provider.errorMessage != null) {
                    return _buildError(provider.errorMessage!);
                  }

                  if (provider.results.isEmpty) {
                    return _buildEmptyState(provider.lastQuery);
                  }

                  return _buildResults(provider.results);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Center(
      child: Image.asset(
        'assets/images/search_tab_image.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load results',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _onSearch, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'No movies found for "$query". Try another keyword.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildResults(List<MovieModel> movies) {
    final rows = <Widget>[];
    for (int i = 0; i < movies.length; i += 2) {
      final rowMovies = movies.skip(i).take(2).toList();
      rows.add(
        Row(
          children: List.generate(2, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 0 ? 12 : 0),
                child: index < rowMovies.length
                    ? _buildResultTile(rowMovies[index])
                    : const SizedBox(),
              ),
            );
          }),
        ),
      );
      if (i + 2 < movies.length) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(children: rows),
    );
  }

  Widget _buildResultTile(MovieModel movie) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).pushNamed(AppRoutes.movieDetails, arguments: movie);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.65,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  _buildPoster(movie.posterPath),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            movie.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _buildSubtitle(movie),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(MovieModel movie) {
    final year = movie.year?.toString() ?? 'Year N/A';
    final genre =
        movie.category ??
        ((movie.genres != null && movie.genres!.isNotEmpty)
            ? movie.genres!.first
            : 'Genre N/A');
    final runtime = movie.runtime != null ? '${movie.runtime} mins' : null;
    final parts = [year, genre, if (runtime != null) runtime];
    return parts.join(' • ');
  }

  Widget _buildPoster(String path, {double? width, double? height}) {
    if (path.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: path,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) =>
              _buildPosterFallback(width, height),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPosterFallback(width, height),
      ),
    );
  }

  Widget _buildPosterFallback(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.movie, color: Colors.white54, size: 32),
    );
  }
}
