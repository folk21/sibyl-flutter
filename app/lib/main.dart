import 'package:flutter/material.dart';

import 'demo/demo_retrieval.dart';
import 'runtime/runtime_loader.dart';
import 'ui/sibyl_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SibylApp());
}

class SibylApp extends StatelessWidget {
  const SibylApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sibyl',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF524F73)),
      useMaterial3: true,
    ),
    home: const _RuntimeEntry(),
  );
}

class _RuntimeEntry extends StatefulWidget {
  const _RuntimeEntry();

  @override
  State<_RuntimeEntry> createState() => _RuntimeEntryState();
}

class _RuntimeEntryState extends State<_RuntimeEntry> {
  late final Future<RuntimeBundle?> _runtime = _load();
  RuntimeBundle? _loaded;

  Future<RuntimeBundle?> _load() async {
    final bundle = await loadRuntimeFromEnvironment();
    if (mounted) {
      _loaded = bundle;
    } else {
      bundle?.close?.call();
    }
    return bundle;
  }

  @override
  void dispose() {
    _loaded?.close?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<RuntimeBundle?>(
    future: _runtime,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return SibylHome(
          retrieval: null,
          isDemo: false,
          corpusError: '${snapshot.error}',
          runtimeLabel: 'Cannot open local corpus: ${snapshot.error}',
        );
      }
      if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final bundle = snapshot.data;
      return SibylHome(
        isDemo: bundle == null,
        runtimeLabel: bundle?.label,
        retrieval: bundle == null ? const DemoRetrievalService() : bundle.freeform,
        guided: bundle?.guided,
      );
    },
  );
}
