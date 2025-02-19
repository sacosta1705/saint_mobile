import 'package:flutter/material.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';
import 'package:saint_mobile/widgets/responsive_layout.dart';

class SetupCheckScreen extends StatelessWidget {
  final SettingsHelper settingsHelper;
  final Widget Function(BuildContext) onSetupComplete;
  final Widget Function(BuildContext) onSetupNeeded;

  const SetupCheckScreen({
    super.key,
    required this.settingsHelper,
    required this.onSetupComplete,
    required this.onSetupNeeded,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: settingsHelper.isInitialSetupDone(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SaintColors.primary,
                    SaintColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: SaintColors.white,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Text(
                      "Iniciando aplicacion...",
                      style: TextStyle(
                        color: SaintColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        return snapshot.data == true
            ? onSetupComplete(context)
            : onSetupNeeded(context);
      },
    );
  }
}
