class SearchResultItem {
  final String id;
  final String description;
  final String? secondaryId;
  final double? price1;
  final double? pricei1;
  final Map<String, dynamic> originalData;

  SearchResultItem({
    required this.id,
    required this.description,
    this.secondaryId,
    this.price1,
    this.pricei1,
    required this.originalData,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json, String type) {
    switch (type) {
      case 'Cliente':
        return SearchResultItem(
          id: json['codclie'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          secondaryId: json['id3'] as String?,
          originalData: json,
        );
      case 'Producto':
        return SearchResultItem(
          id: json['codprod'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          price1: (json['precio1'] as num?)?.toDouble(),
          pricei1: (json['precioi1'] as num?)?.toDouble(),
          originalData: json,
        );
      case 'Vendedor':
        return SearchResultItem(
          id: json['codvend'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          originalData: json,
        );
      case 'Depósito':
        return SearchResultItem(
          id: json['codubic'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          originalData: json,
        );
      case 'InstrumentoPago':
        return SearchResultItem(
          id: json['codtarj'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          originalData: json,
        );
      default:
        return SearchResultItem(
          id: json['id']?.toString() ??
              json.keys.firstWhere((k) => k.toLowerCase().contains("cod"),
                  orElse: () => "N/A"),
          description: json['descrip']?.toString() ??
              json.keys.firstWhere((k) => k.toLowerCase().contains("desc"),
                  orElse: () => "N/A"),
          originalData: json,
        );
    }
  }
}
