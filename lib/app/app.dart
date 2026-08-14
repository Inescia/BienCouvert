import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/ads/ad_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class PoneyAuChaudApp extends ConsumerStatefulWidget {
  const PoneyAuChaudApp({super.key});

  @override
  ConsumerState<PoneyAuChaudApp> createState() => _PoneyAuChaudAppState();
}

class _PoneyAuChaudAppState extends ConsumerState<PoneyAuChaudApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adServiceProvider).warmUp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Bien Couvert',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: kAppSystemUiOverlay,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
