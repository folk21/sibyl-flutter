import '../retrieval/contracts.dart';

/// Web intentionally uses synthetic fixtures until a reviewed WASM corpus adapter exists.
class RuntimeBundle {
  const RuntimeBundle({required this.label, required this.guided, this.freeform, this.close});
  final String label;
  final GuidedRetrievalService? guided;
  final RetrievalService? freeform;
  final void Function()? close;
}

Future<RuntimeBundle?> loadRuntimeFromEnvironment() async => null;
