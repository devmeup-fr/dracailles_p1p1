# Makefile - P1P1 Dracailles (Flutter)
# Usage: make help

SHELL := /bin/bash

FLUTTER ?= flutter
DART ?= dart
PYTHON ?= python3

# --- Build number (Unix timestamp seconds) ---
# Android: must be <= 2100000000 (Google Play). Unix seconds stays under that until 2038.
BUILD_NUMBER := $(shell date +%s)

# --- Android device (flutter devices) ---
# Example: make android-install DEVICE=RF8R50V5JJA
DEVICE ?=
DEVICE_FLAG := $(if $(DEVICE),-d $(DEVICE),)

# --- Web ---
WEB_PORT ?= 8765

.DEFAULT_GOAL := help

.PHONY: help data images \
        android-run android-apk android-install android-bundle \
        web-run web-build web-serve \
        clean deps fmt analyze test check

help:
	@echo "P1P1 Dracailles - Makefile"
	@echo ""
	@echo "Data:"
	@echo "  make data                # Regenerate assets/sets/<id>/data.json from tool/sets/<id>/"
	@echo "  make images              # data + download missing card images (Pillow required)"
	@echo ""
	@echo "Common:"
	@echo "  make deps                # flutter pub get"
	@echo "  make fmt                 # dart format ."
	@echo "  make analyze             # flutter analyze"
	@echo "  make test                # flutter test"
	@echo "  make check               # deps + fmt + analyze + test"
	@echo ""
	@echo "Android:"
	@echo "  make android-run         # [DEVICE=<id>]"
	@echo "  make android-apk         # release APK"
	@echo "  make android-install     # release APK installed on the device [DEVICE=<id>]"
	@echo "  make android-bundle"
	@echo ""
	@echo "Web:"
	@echo "  make web-run             # flutter run -d chrome"
	@echo "  make web-build"
	@echo "  make web-serve           # serve build/web on http://localhost:$(WEB_PORT)"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean"

# --- 1) Data ---
data:
	$(PYTHON) tool/build_data.py

images:
	$(PYTHON) tool/build_data.py --images

# --- 2) Android ---
# No product flavors are configured in android/app/build.gradle for this project.

android-run:
	$(FLUTTER) run $(DEVICE_FLAG) -t lib/main.dart

android-apk:
	$(FLUTTER) build apk --release -t lib/main.dart --build-number=$(BUILD_NUMBER)

android-install: android-apk
	$(FLUTTER) install $(DEVICE_FLAG)

android-bundle:
	$(FLUTTER) build appbundle --release -t lib/main.dart --build-number=$(BUILD_NUMBER)

# --- 3) Web ---
web-run:
	$(FLUTTER) run -d chrome -t lib/main.dart

web-build:
	$(FLUTTER) build web --release -t lib/main.dart

web-serve: web-build
	$(PYTHON) -m http.server $(WEB_PORT) --directory build/web

# --- Clean ---
clean:
	$(FLUTTER) clean

# --- Flutter Standards ---
deps:
	$(FLUTTER) pub get

fmt:
	$(DART) format .

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

check: deps fmt analyze test
