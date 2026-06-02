import 'lexical_item.dart';

/// Kết quả trả về từ endpoint /api/lexical/lookup
class LookupResult {
  final String source; // "vault" hoặc "generated"
  final String? id;
  final LexicalItem data;

  LookupResult({required this.source, this.id, required this.data});

  bool get isFromVault => source == 'vault';

  factory LookupResult.fromJson(Map<String, dynamic> json) {
    return LookupResult(
      source: json['source'] ?? 'generated',
      id: json['id'] as String?,
      data: LexicalItem.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// Kết quả phân trang từ endpoint GET /api/lexical
class PagedResult {
  final List<LexicalItem> items;
  final int total;
  final int page;
  final int pageSize;

  PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;

  factory PagedResult.fromJson(Map<String, dynamic> json) {
    return PagedResult(
      items: (json['items'] as List?)
              ?.map((e) => LexicalItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }
}
