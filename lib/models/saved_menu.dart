import 'dart:convert';

class SavedMenu {
  final String id;
  final String officeId;
  final String officeName;
  final String restaurantId;
  final String restaurantName;
  final String buildingName;
  final int seq;
  final String title;
  final String savedDate; // YYYY-MM-DD
  final DateTime savedAt;
  final String filePath; // Relative or absolute file path
  final String? base64Data; // Web fallback storage

  SavedMenu({
    required this.id,
    required this.officeId,
    required this.officeName,
    required this.restaurantId,
    required this.restaurantName,
    required this.buildingName,
    required this.seq,
    required this.title,
    required this.savedDate,
    required this.savedAt,
    required this.filePath,
    this.base64Data,
  });

  /// Extract concise building/hall name from restaurant name
  /// e.g. "구내식당(오름동 4층)" -> "오름동4층"
  /// "1동 진주홀(1동-2, 136호)" -> "1동진주홀"
  static String extractBuildingName(String rstrntName) {
    final trimmed = rstrntName.trim();

    // Pattern 1: Starts with 구내식당(...) -> take content inside parentheses
    final match = RegExp(r'^구내식당\((.+)\)$').firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!.replaceAll(RegExp(r'\s+'), '');
    }

    // Pattern 2: Has prefix before parenthesis, e.g., "1동 진주홀(...)"
    final parenIdx = trimmed.indexOf('(');
    if (parenIdx > 0) {
      final prefix = trimmed.substring(0, parenIdx).trim();
      if (prefix.isNotEmpty && prefix != '구내식당') {
        return prefix.replaceAll(RegExp(r'\s+'), '');
      }
    }

    // Fallback: strip whitespace and parenthesis
    final cleaned = trimmed.replaceAll(RegExp(r'[\(\)\s]'), '');
    return cleaned.isNotEmpty ? cleaned : '식당';
  }

  /// Format Date as YYYY-MM-DD
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'officeId': officeId,
      'officeName': officeName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'buildingName': buildingName,
      'seq': seq,
      'title': title,
      'savedDate': savedDate,
      'savedAt': savedAt.toIso8601String(),
      'filePath': filePath,
      if (base64Data != null) 'base64Data': base64Data,
    };
  }

  factory SavedMenu.fromMap(Map<String, dynamic> map) {
    return SavedMenu(
      id: map['id'] as String,
      officeId: map['officeId'] as String,
      officeName: map['officeName'] as String,
      restaurantId: map['restaurantId'] as String,
      restaurantName: map['restaurantName'] as String,
      buildingName: map['buildingName'] as String? ??
          extractBuildingName(map['restaurantName'] as String? ?? ''),
      seq: map['seq'] as int? ?? 1,
      title: map['title'] as String,
      savedDate: map['savedDate'] as String,
      savedAt: DateTime.parse(map['savedAt'] as String),
      filePath: map['filePath'] as String,
      base64Data: map['base64Data'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SavedMenu.fromJson(String source) =>
      SavedMenu.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
