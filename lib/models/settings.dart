class AppSettings {
  final String? adminPassword;
  final bool isSetupComplete;
  final String? serverUrl;

  AppSettings({
    this.adminPassword,
    this.isSetupComplete = false,
    this.serverUrl,
  });

  AppSettings copyWith({
    String? adminPassword,
    bool? isSetupComplete,
    String? serverUrl,
  }) {
    return AppSettings(
      adminPassword: adminPassword ?? this.adminPassword,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }
}
