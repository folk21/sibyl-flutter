.PHONY: help check check-all test-mobile test-corpus-core test-corpus-builder validate-format validate-sources smoke-corpus format-python build-runtime-corpus download-runtime-model test-flutter test-agents validate-state validate-guided-catalog bootstrap-flutter run-macos run-web

help:
	@echo 'Sibyl Flutter commands: bootstrap-flutter, run-macos, run-web, check, check-all, test-flutter, test-agents, smoke-corpus, build-runtime-corpus, download-runtime-model'

check: test-corpus-core test-corpus-builder validate-format validate-sources validate-state validate-guided-catalog
	@echo 'Python / format / state baseline passed (Flutter verification is in check-all).'

check-all: check test-flutter test-agents

bootstrap-flutter:
	cd app && ./bootstrap.sh

run-macos:
	cd app && flutter run -d macos

run-web:
	cd app && flutter run -d chrome

validate-state:
	python3 tools/specs/validate_state.py

validate-guided-catalog:
	python3 tools/sync_guided_catalog.py --check
	python3 -m unittest discover -s tools/tests -p 'test_*.py'

test-agents:
	python3 -m unittest discover -s tools/specs/tests -p 'test_*.py'
	python3 -m unittest discover -s tools/agent-pipeline/tests -p 'test_*.py'

test-flutter:
	cd app && flutter pub get && flutter test && flutter analyze && dart format --output=none --set-exit-if-changed lib test

test-corpus-core:
	PYTHONPATH=corpus-core/src python -m pytest corpus-core/tests

test-corpus-builder:
	PYTHONPATH=corpus-core/src:corpus-builder/src python -m pytest corpus-builder/tests

validate-format:
	python corpus-format/tools/validate_schema.py

validate-sources:
	python corpus-sources/tools/validate_registry.py

RUNTIME_CORPUS_DIR ?= corpus-builder/data/output
PREPARED_SOURCE_ROOT ?= corpus-builder/data/work
QUESTIONS_PATH ?= corpus-curation/questions.json
CURATION_ROOT ?= corpus-curation/curated
TRANSLATION_ROOT ?= corpus-builder/data/translations/validated
MODEL_DIR ?= corpus-builder/data/runtime-models/multilingual-e5-small

build-runtime-corpus:
	PYTHONPATH=corpus-core/src:corpus-builder/src python -m sibyl_corpus_builder.cli build-available \
		--config corpus-builder/config/real-text.toml --source-root "$(PREPARED_SOURCE_ROOT)" \
		--questions "$(QUESTIONS_PATH)" --curation-root "$(CURATION_ROOT)" \
		--translation-root "$(TRANSLATION_ROOT)" --output "$(RUNTIME_CORPUS_DIR)"

download-runtime-model:
	cd corpus-builder && PYTHONPATH=../corpus-core/src:src python -m sibyl_corpus_builder.cli download-runtime-model \
		--config config/real-text.toml --output data/runtime-models/multilingual-e5-small

smoke-corpus:
	@tmp_dir=$$(mktemp -d); trap 'rm -rf "$$tmp_dir"' EXIT; \
	PYTHONPATH=corpus-core/src:corpus-builder/src python -m sibyl_corpus_builder.cli build \
		--config corpus-builder/config/example.toml --source test-corpus/sources --output "$$tmp_dir/output"; \
	PYTHONPATH=corpus-core/src:corpus-builder/src python -m sibyl_corpus_builder.cli validate \
		--corpus "$$tmp_dir/output/corpus.db"

format-python:
	python -m ruff check --fix corpus-core corpus-builder && python -m ruff format corpus-core corpus-builder
