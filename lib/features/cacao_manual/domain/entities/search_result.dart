import 'package:equatable/equatable.dart';
import 'manual_section.dart';

class SearchResult extends Equatable {
  final ManualSection section;
  final double relevanceScore;
  final String? matchedSnippet;
  final SearchResultSource source;

  const SearchResult({
    required this.section,
    required this.relevanceScore,
    this.matchedSnippet,
    required this.source,
  });

  @override
  List<Object?> get props => [section, relevanceScore, matchedSnippet, source];
}

enum SearchResultSource {
  ftsSearch,
  mlMapping,
  tagMatch,
}
