import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(kAppSystemUiOverlay);
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Outfit',
    ], await rootBundle.loadString('google_fonts/OFL-Outfit.txt'));
    yield LicenseEntryWithLineBreaks([
      'Fraunces',
    ], await rootBundle.loadString('google_fonts/OFL-Fraunces.txt'));
  });
  runApp(const ProviderScope(child: PoneyAuChaudApp()));
}
