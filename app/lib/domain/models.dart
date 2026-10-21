/// The length is a persisted choice, never an instruction to truncate text.
enum PassageLength { short, standard, extended }

enum WorkCategory { literature, philosophy, sacredText }

enum PassageTextRole { original, humanTranslation, machineTranslation }

/// A single text realization read verbatim from an approved corpus version.
class PassageText {
  const PassageText({
    required this.language,
    required this.role,
    required this.text,
    this.translator,
    this.translationProvider,
    this.translationModel,
  });

  final String language;
  final PassageTextRole role;
  final String text;
  final String? translator;
  final String? translationProvider;
  final String? translationModel;
}

/// All stored language/translation realizations for one prepared passage length.
class PassageVariant {
  PassageVariant({required this.length, required List<PassageText> texts})
    : texts = List.unmodifiable(texts) {
    if (texts.isEmpty) throw ArgumentError('Passage variant needs stored text');
  }

  final PassageLength length;
  final List<PassageText> texts;

  static int _priority(PassageText item) => switch (item.role) {
    PassageTextRole.original => 0,
    PassageTextRole.humanTranslation => 1,
    PassageTextRole.machineTranslation => 2,
  };

  PassageText preferredText([String language = 'ru']) {
    final sameLanguage = texts.where((text) => text.language == language).toList();
    final options = sameLanguage.isNotEmpty ? sameLanguage : [...texts];
    options.sort((a, b) => _priority(a).compareTo(_priority(b)));
    return options.first;
  }

  /// Original plus preferred translation; no translation is produced at runtime.
  List<PassageText> parallelDisplayTexts([String language = 'ru']) {
    final preferred = preferredText(language);
    final originals = texts.where((text) => text.role == PassageTextRole.original);
    if (originals.isEmpty || preferred.role == PassageTextRole.original) {
      return [preferred];
    }
    final original = originals.first;
    if (original.language == preferred.language && original.text == preferred.text) {
      return [original];
    }
    return [original, preferred];
  }
}

class Passage {
  Passage({
    required this.id,
    required this.author,
    required this.work,
    required this.originalLanguage,
    required Map<PassageLength, PassageVariant> variants,
    this.location,
    this.category = WorkCategory.literature,
  }) : variants = Map.unmodifiable(variants) {
    if (variants.isEmpty) throw ArgumentError('Passage requires stored variants');
  }

  final String id;
  final String author;
  final String work;
  final String originalLanguage;
  final String? location;
  final WorkCategory category;
  final Map<PassageLength, PassageVariant> variants;
}

class Candidate {
  const Candidate({
    required this.passage,
    required this.semanticScore,
    this.qualityScore = 1,
    this.historyWeight = 1,
    this.diversityWeight = 1,
  });

  final Passage passage;
  final double semanticScore;
  final double qualityScore;
  final double historyWeight;
  final double diversityWeight;
}

class Answer {
  const Answer({required this.question, required this.passage, required this.variant});
  final String question;
  final Passage passage;
  final PassageVariant variant;
}

class GuidedQuestion {
  const GuidedQuestion({required this.id, required this.text, this.kind, this.theme});
  final String id;
  final String text;
  final String? kind;
  final String? theme;
}

class SavedEncounter {
  const SavedEncounter({required this.id, required this.question, required this.passageId, this.note});
  final String id;
  final String question;
  final String passageId;
  final String? note;
}
