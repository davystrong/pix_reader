import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pix_reader/generator_homepage.dart';

import 'scanner_homepage.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

enum AppMode {
  scanner,
  generator,
}

final appModeProvider = StateProvider<AppMode>(
  (ref) => defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android
      ? AppMode.scanner
      : AppMode.generator,
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Pix Checkout',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: ref.watch(appModeProvider) == AppMode.scanner
          ? const ScannerHomePage()
          : const GeneratorHomePage(),
    );
  }
}
