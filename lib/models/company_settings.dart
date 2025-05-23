class CompanySettings {
  final String name;
  final String taxidentifier;
  final int countrycode;
  final int statecode;
  final int citycode;
  final String address1;
  final String address2;
  final String taxcode;
  final String referencesymbol;
  final double referencerate;
  final double taxretentionperct;

  CompanySettings({
    required this.name,
    required this.taxidentifier,
    required this.countrycode,
    required this.statecode,
    required this.citycode,
    required this.address1,
    required this.address2,
    required this.taxcode,
    required this.referencesymbol,
    required this.referencerate,
    required this.taxretentionperct,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    double parseDoubleSafe(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    int parseIntSafe(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    return CompanySettings(
      name: json['descrip'] ?? '',
      taxidentifier: json['rif'] ?? '',
      countrycode: parseIntSafe(json['pais']),
      statecode: parseIntSafe(json['estado']),
      citycode: parseIntSafe(json['ciudad']),
      address1: json['direc1'] ?? '',
      address2: json['direc2'] ?? '',
      taxcode: json['codtaxs'] ?? 'IVA',
      referencesymbol: json['simbfac'] ?? '',
      referencerate: parseDoubleSafe(json['factorm']),
      taxretentionperct: parseDoubleSafe(json['porctreten']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'name': name,
      'tax_identifier': taxidentifier,
      'country_code': countrycode,
      'state_code': statecode,
      'city_code': citycode,
      'address1': address1,
      'address2': address2,
      'tax_code': taxcode,
      'reference_symbol': referencesymbol,
      'reference_rate': referencerate,
      'tax_retention_percentage': taxretentionperct,
    };
  }

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    return CompanySettings(
      name: map['name'] as String,
      taxidentifier: map['tax_identifier'] as String,
      countrycode: map['country_code'] as int,
      statecode: map['state_code'] as int,
      citycode: map['city_code'] as int,
      address1: map['address1'] as String,
      address2: map['address2'] as String,
      taxcode: map['tax_code'] as String,
      referencesymbol: map['reference_symbol'] as String,
      referencerate: (map['reference_rate'] as num?)?.toDouble() ?? 0.0,
      taxretentionperct:
          (map['tax_retention_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
