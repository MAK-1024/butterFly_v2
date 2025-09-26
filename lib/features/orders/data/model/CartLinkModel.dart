
class CartLink {
  final String link;
  final int pieces;
  final String? note;

  CartLink({
    required this.link,
    required this.pieces,
    this.note,
  }) {
    if (link.isEmpty) {
      throw ArgumentError('Link cannot be empty');
    }
  }

  factory CartLink.fromJson(Map<String, dynamic> json) {
    try {
      return CartLink(
        link: json['link'] as String? ?? '',
        pieces: (json['pieces'] as int? ?? 0),
        note: json['note'] as String?,
      );
    } catch (e) {
      throw FormatException('Failed to parse CartLink: $e');
    }
  }

  factory CartLink.fromFirestore(Map<String, dynamic> data) {
    return CartLink(
      link: data['link'] as String,
      pieces: data['pieces'] as int,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'link': link,
    'pieces': pieces,
    'note': note,
  };

  Map<String, dynamic> toFirestore() => {
    'link': link,
    'pieces': pieces,
    'note': note,
  };

  CartLink copyWith({
    String? link,
    int? pieces,
    String? note,
    DateTime? addedAt,
  }) {
    return CartLink(
      link: link ?? this.link,
      pieces: pieces ?? this.pieces,
      note: note ?? this.note,
    );
  }

  String? get sheinProductId {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;

    final pattern = RegExp(r'/(\d+)-');
    final match = pattern.firstMatch(uri.path);
    return match?.group(1);
  }

  bool get isValidSheinLink {
    return link.contains('shein.com') && sheinProductId != null;
  }

  @override
  String toString() {
    return 'CartLink(link: $link, pieces: $pieces, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartLink &&
        other.link == link &&
        other.pieces == pieces &&
        other.note == note;
  }

  @override
  int get hashCode => link.hashCode ^ pieces.hashCode ^ note.hashCode;
}