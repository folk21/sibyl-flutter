import 'package:flutter/material.dart';

import '../domain/models.dart';

/// A searchable, theme-grouped catalog of prompts, including unavailable ones.
/// Corpus availability affects answering, never whether a prompt is visible.
class GuidedQuestionPicker extends StatefulWidget {
  const GuidedQuestionPicker({
    super.key,
    required this.questions,
    required this.selectedId,
    required this.availableIds,
    required this.onSelected,
  });

  final List<GuidedQuestion> questions;
  final String? selectedId;
  final Set<String> availableIds;
  final ValueChanged<GuidedQuestion> onSelected;

  @override
  State<GuidedQuestionPicker> createState() => _GuidedQuestionPickerState();
}

class _GuidedQuestionPickerState extends State<GuidedQuestionPicker> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  static String _heading(String theme) => theme
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final query = _filter.text.trim().toLowerCase();
    final groups = <String, List<GuidedQuestion>>{};
    for (final question in widget.questions) {
      if (query.isNotEmpty &&
          !question.text.toLowerCase().contains(query) &&
          !_heading(question.theme ?? '').toLowerCase().contains(query)) {
        continue;
      }
      groups.putIfAbsent(question.theme ?? '', () => []).add(question);
    }
    final firstTheme = widget.questions.firstOrNull?.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('guided-search'),
          controller: _filter,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Search questions and states',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        for (final group in groups.entries)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: ValueKey('theme-${group.key}-${query.isEmpty ? 'all' : 'filtered'}'),
              initiallyExpanded: query.isNotEmpty || group.key == firstTheme,
              title: Text(_heading(group.key)),
              subtitle: Text('${group.value.length} prompts'),
              children: [
                for (final prompt in group.value)
                  ListTile(
                    key: Key('guided-${prompt.id}'),
                    selected: widget.selectedId == prompt.id,
                    leading: Icon(widget.selectedId == prompt.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
                    title: Text(prompt.text),
                    subtitle: prompt.kind == 'state' ? const Text('State') : null,
                    trailing: widget.availableIds.contains(prompt.id)
                        ? const Tooltip(
                            message: 'Stored literary passages available',
                            child: Icon(Icons.menu_book_outlined),
                          )
                        : null,
                    onTap: () => widget.onSelected(prompt),
                  ),
              ],
            ),
          ),
        if (groups.isEmpty) const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No matching questions or states.'),
        ),
      ],
    );
  }
}
