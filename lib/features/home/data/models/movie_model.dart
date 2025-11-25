class MovieModel {
  final String id;
  final String title;
  final String? tagline;
  final String posterPath;
  final double rating;
  final String? category;
  final List<String>? cast;
  final int? year;
  final int? runtime;
  final String? summary;
  final String? descriptionFull;
  final List<String>? genres;
  final String? backgroundImage;
  final String? language;
  final String? trailerCode;
  final List<String>? screenshotUrls;

  MovieModel({
    required this.id,
    required this.title,
    this.tagline,
    required this.posterPath,
    required this.rating,
    this.category,
    this.cast,
    this.year,
    this.runtime,
    this.summary,
    this.descriptionFull,
    this.genres,
    this.backgroundImage,
    this.language,
    this.trailerCode,
    this.screenshotUrls,
  });

  MovieModel copyWith({
    String? id,
    String? title,
    String? tagline,
    String? posterPath,
    double? rating,
    String? category,
    List<String>? cast,
    int? year,
    int? runtime,
    String? summary,
    String? descriptionFull,
    List<String>? genres,
    String? backgroundImage,
    String? language,
    String? trailerCode,
    List<String>? screenshotUrls,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      tagline: tagline ?? this.tagline,
      posterPath: posterPath ?? this.posterPath,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      cast: cast ?? this.cast,
      year: year ?? this.year,
      runtime: runtime ?? this.runtime,
      summary: summary ?? this.summary,
      descriptionFull: descriptionFull ?? this.descriptionFull,
      genres: genres ?? this.genres,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      language: language ?? this.language,
      trailerCode: trailerCode ?? this.trailerCode,
      screenshotUrls: screenshotUrls ?? this.screenshotUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'tagline': tagline,
      'posterPath': posterPath,
      'rating': rating,
      'category': category,
      'cast': cast,
      'year': year,
      'runtime': runtime,
      'summary': summary,
      'descriptionFull': descriptionFull,
      'genres': genres,
      'backgroundImage': backgroundImage,
      'language': language,
      'trailerCode': trailerCode,
      'screenshotUrls': screenshotUrls,
    };
  }

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      tagline: json['tagline'] as String?,
      posterPath: json['posterPath']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String?,
      cast: json['cast'] != null
          ? List<String>.from(json['cast'] as List)
          : null,
      year: json['year'] as int?,
      runtime: json['runtime'] as int?,
      summary: json['summary'] as String?,
      descriptionFull: json['descriptionFull'] as String?,
      genres: json['genres'] != null
          ? List<String>.from(json['genres'] as List)
          : null,
      backgroundImage: json['backgroundImage'] as String?,
      language: json['language'] as String?,
      trailerCode: json['trailerCode'] as String?,
      screenshotUrls: json['screenshotUrls'] != null
          ? List<String>.from(json['screenshotUrls'] as List)
          : null,
    );
  }

  factory MovieModel.fromYtsJson(Map<String, dynamic> json) {
    return MovieModel(
      id: (json['id'] ?? json['movie_id']).toString(),
      title: json['title']?.toString() ?? 'Unknown',
      tagline: json['title_long'] as String?,
      posterPath:
          (json['large_cover_image'] as String?) ??
          (json['medium_cover_image'] as String?) ??
          (json['small_cover_image'] as String?) ??
          '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      category: _extractPrimaryCategory(json),
      cast: _extractCast(json),
      year: json['year'] as int?,
      runtime: json['runtime'] as int?,
      summary: _extractSummary(json),
      descriptionFull: json['description_full'] as String?,
      genres: json['genres'] != null
          ? (json['genres'] as List).map((genre) => genre.toString()).toList()
          : null,
      backgroundImage:
          json['background_image_original'] as String? ??
          json['background_image'] as String?,
      language: json['language'] as String?,
      trailerCode: json['yt_trailer_code'] as String?,
      screenshotUrls: _extractScreenshots(json),
    );
  }

  static String? _extractPrimaryCategory(Map<String, dynamic> json) {
    final genres = json['genres'];
    if (genres is List && genres.isNotEmpty) {
      return genres.first.toString();
    }
    return null;
  }

  static String? _extractSummary(Map<String, dynamic> json) {
    final summary = (json['summary'] as String?)?.trim();
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }
    final descriptionFull = (json['description_full'] as String?)?.trim();
    if (descriptionFull != null && descriptionFull.isNotEmpty) {
      return descriptionFull;
    }
    return null;
  }

  static List<String>? _extractCast(Map<String, dynamic> json) {
    final cast = json['cast'];
    if (cast is List && cast.isNotEmpty) {
      return cast
          .map((member) {
            if (member is Map<String, dynamic>) {
              final name = member['name']?.toString();
              final character = member['character_name']?.toString();
              if (name != null && name.isNotEmpty) {
                return character != null && character.isNotEmpty
                    ? '$name as $character'
                    : name;
              }
            }
            return null;
          })
          .whereType<String>()
          .toList();
    }
    return null;
  }

  static List<String>? _extractScreenshots(Map<String, dynamic> json) {
    final screenshots = <String>[];
    for (var i = 1; i <= 3; i++) {
      final key = 'large_screenshot_image$i';
      final fallbackKey = 'medium_screenshot_image$i';
      final screenshot =
          (json[key] as String?) ?? (json[fallbackKey] as String?);
      if (screenshot != null && screenshot.isNotEmpty) {
        screenshots.add(screenshot);
      }
    }
    return screenshots.isEmpty ? null : screenshots;
  }
}
