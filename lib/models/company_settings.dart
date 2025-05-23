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
  final String referencerate;
  final String taxretentionperct;

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
    return CompanySettings(
      name: json['descrip'],
      taxidentifier: json['rif'],
      countrycode: json['pais'],
      statecode: json['estado'],
      citycode: json['ciudad'],
      address1: json['direc1'],
      address2: json['direc2'],
      taxcode: json['codtaxs'],
      referencesymbol: json['simbfac'],
      referencerate: json['factorm'],
      taxretentionperct: json['porctreten'],
    );
  }
}
