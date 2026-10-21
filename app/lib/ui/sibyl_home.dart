import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/selection_engine.dart';
import '../retrieval/contracts.dart';
import '../runtime/guided_question_catalog.dart';
import 'guided_question_picker.dart';

enum _InputMode { guided, freeForm }

/// A presentation-only home screen; retrieval and weighted selection stay outside the widget tree.
class SibylHome extends StatefulWidget {
  const SibylHome({
    super.key,
    required this.retrieval,
    required this.isDemo,
    this.guided,
    this.runtimeLabel,
    this.corpusError,
    this.selector,
    this.catalogLoader,
  });

  final RetrievalService? retrieval;
  final GuidedRetrievalService? guided;
  final bool isDemo;
  final String? runtimeLabel;
  final String? corpusError;
  final SelectionEngine? selector;
  final Future<List<GuidedQuestion>> Function()? catalogLoader;

  @override
  State<SibylHome> createState() => _SibylHomeState();
}

class _SibylHomeState extends State<SibylHome> {
  final _question = TextEditingController();
  final _scroll = ScrollController();
  final List<Answer> _history = [];
  final List<Answer> _saved = [];
  late final SelectionEngine _selector = widget.selector ?? SelectionEngine();
  _InputMode _mode = _InputMode.guided;
  List<GuidedQuestion> _guidedQuestions = [];
  GuidedQuestion? _selectedGuided;
  Set<String> _availableGuidedIds = {};
  String? _catalogError;
  String? _availabilityError;
  Answer? _answer;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final catalog = await (widget.catalogLoader?.call() ?? loadGuidedQuestionCatalog());
      if (!mounted) return;
      setState(() {
        _guidedQuestions = catalog;
        _selectedGuided = catalog.firstOrNull;
      });
    } catch (error) {
      if (mounted) setState(() => _catalogError = 'Cannot load packaged questions: $error');
      return;
    }
    if (widget.guided == null) return;
    try {
      final available = await widget.guided!.availableQuestions();
      if (!mounted) return;
      setState(() => _availableGuidedIds = available.map((q) => q.id).toSet());
    } catch (error) {
      if (mounted) {
        setState(() => _availabilityError = 'Cannot check local passage mappings: $error');
      }
    }
  }

  String _guidedStatus() {
    if (widget.corpusError != null) {
      return 'Local corpus could not be opened. Questions remain available, but literary answers are disabled.';
    }
    if (widget.guided == null) {
      return widget.isDemo
          ? 'Literary corpus is not installed. Questions are available to browse, but literary answers require a local corpus.'
          : 'This corpus does not provide guided passage mappings.';
    }
    if (_availabilityError != null) return _availabilityError!;
    if (_selectedGuided != null && !_availableGuidedIds.contains(_selectedGuided!.id)) {
      return 'No stored literary passages are mapped to this question in the installed corpus.';
    }
    return '${_availableGuidedIds.intersection(_guidedQuestions.map((q) => q.id).toSet()).length} of '
        '${_guidedQuestions.length} prompts have local literary answers.';
  }

  Future<void> _findPassage() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guided = _mode == _InputMode.guided;
      if (guided && (_selectedGuided == null ||
          widget.guided == null || !_availableGuidedIds.contains(_selectedGuided!.id))) {
        throw StateError('No stored literary answer is available for this question.');
      }
      if (!guided && widget.retrieval == null) {
        throw StateError('Local free-form embedding is not available for this corpus.');
      }
      final question = guided ? _selectedGuided!.text : _question.text.trim();
      final candidates = guided
          ? await widget.guided!.candidates(_selectedGuided!.id, 50)
          : await widget.retrieval!.candidates(question, 50);
      final selected = _selector.select(
        question: question,
        candidates: candidates,
        policy: guided ? SelectionPolicy.guided : SelectionPolicy.defaults,
      );
      if (!mounted) return;
      setState(() {
        if (selected == null) {
          _error = 'No eligible stored passage was found.';
        } else {
          _answer = selected;
          _history.add(selected);
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Local retrieval failed: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canFind = !_loading && (_mode == _InputMode.guided
        ? widget.guided != null && _selectedGuided != null &&
            _availableGuidedIds.contains(_selectedGuided!.id)
        : widget.retrieval != null && _question.text.trim().isNotEmpty);
    return Scaffold(
      appBar: AppBar(title: const Text('Sibyl')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(22),
              children: [
                Text('Literary discovery', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(widget.isDemo
                    ? 'Explore the interface with synthetic test passages. These are not literary quotations.'
                    : 'Read exact stored passages from your local corpus. No question is sent to a server.'),
                if (widget.runtimeLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.runtimeLabel!, style: TextStyle(color: scheme.secondary)),
                ],
                const SizedBox(height: 20),
                if (_guidedQuestions.isNotEmpty) ...[
                  Wrap(spacing: 10, children: [
                    ChoiceChip(
                      label: const Text('Guided questions'),
                      selected: _mode == _InputMode.guided,
                      onSelected: (_) => setState(() {
                        _mode = _InputMode.guided;
                        _answer = null;
                        _error = null;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Own question'),
                      selected: _mode == _InputMode.freeForm,
                      onSelected: (_) => setState(() {
                        _mode = _InputMode.freeForm;
                        _answer = null;
                        _error = null;
                      }),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],
                if (_mode == _InputMode.guided) ...[
                  if (_catalogError != null)
                    Text(_catalogError!, style: TextStyle(color: scheme.error))
                  else if (_guidedQuestions.isEmpty)
                    const Text('Loading prepared questions…')
                  else ...[
                    Text('Prepared questions and states',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('${_guidedQuestions.where((q) => q.kind == 'question').length} questions · '
                        '${_guidedQuestions.where((q) => q.kind == 'state').length} states'),
                    const SizedBox(height: 12),
                    Text('Selected: ${_selectedGuided?.text ?? 'None'}',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(_guidedStatus(), style: TextStyle(color: scheme.secondary)),
                  ],
                ] else
                  TextField(
                    controller: _question,
                    onChanged: (_) => setState(() {
                      _answer = null;
                      _error = null;
                    }),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Your question',
                      hintText: 'What should I consider today?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_mode == _InputMode.freeForm && !widget.isDemo && widget.retrieval == null) ...[
                  const SizedBox(height: 8),
                  const Text('Free-form E5 inference is not ported yet. Guided SQLite retrieval remains available.'),
                ],
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: canFind ? _findPassage : null,
                    icon: const Icon(Icons.auto_stories_outlined),
                    label: Text(_loading ? 'Searching locally…' : 'Find passage'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: scheme.error)),
                ],
                if (_answer != null) ...[
                  const SizedBox(height: 22),
                  _AnswerCard(answer: _answer!, isDemo: widget.isDemo),
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, children: [
                    OutlinedButton.icon(
                      onPressed: _saved.any((a) => a.question == _answer!.question && a.passage.id == _answer!.passage.id)
                          ? null : () => setState(() => _saved.add(_answer!)),
                      icon: const Icon(Icons.bookmark_outline),
                      label: const Text('Remember this'),
                    ),
                    OutlinedButton(
                      onPressed: _findPassage,
                      child: const Text('Another passage'),
                    ),
                  ]),
                ],
                if (_mode == _InputMode.guided && _guidedQuestions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  GuidedQuestionPicker(
                    questions: _guidedQuestions,
                    selectedId: _selectedGuided?.id,
                    availableIds: _availableGuidedIds,
                    onSelected: (question) {
                      setState(() {
                        _selectedGuided = question;
                        _answer = null;
                        _error = null;
                      });
                      _scroll.animateTo(0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut);
                    },
                  ),
                ],
                if (_saved.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Saved encounters', style: Theme.of(context).textTheme.titleMedium),
                  for (final item in _saved.reversed.take(3))
                    ListTile(dense: true, title: Text(item.question), subtitle: Text(item.passage.work)),
                ],
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('History', style: Theme.of(context).textTheme.titleMedium),
                  for (final item in _history.reversed.take(5))
                    ListTile(dense: true, title: Text(item.question), subtitle: Text(item.passage.work)),
                ],
                const SizedBox(height: 28),
                Text('History and saved encounters are kept in memory for this session only.',
                  style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer, required this.isDemo});
  final Answer answer;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final displayed = answer.variant.parallelDisplayTexts();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, stored) in displayed.indexed) ...[
              Text(switch (stored.role) {
                PassageTextRole.original => 'Original · ${stored.language}',
                PassageTextRole.humanTranslation => 'Translation · ${stored.language}',
                PassageTextRole.machineTranslation => 'Machine translation · ${stored.language}',
              }, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              SelectableText(stored.text, style: index == 0
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 14),
            ],
            Text('${answer.passage.author} — ${answer.passage.work}',
              style: Theme.of(context).textTheme.titleSmall),
            if (answer.passage.location != null)
              Text(answer.passage.location!, style: Theme.of(context).textTheme.bodySmall),
            if (isDemo) ...[
              const SizedBox(height: 10),
              const Text('DEMO: synthetic fixture, not a literary quotation',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}
