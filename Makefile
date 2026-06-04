# IOS IPA Install — build, run & release
#
#   make app        generate the project + build a Debug app (ad-hoc) for local runs
#   make run        build Debug and launch the app
#   make project    just (re)generate "IOS IPA Install.xcodeproj" from project.yml
#   make dist-app   build the Release app (Developer ID + hardened runtime) into ./dist
#   make notarize   notarize + staple the Release app   (NOTARY_PROFILE=<profile>)
#   make release    notarize, sign the appcast, publish the zip + appcast to the
#                   IOS-IPA-Install-releases GitHub release, then tag this repo
#   make clean      remove the generated project and build artifacts
#
# Requires XcodeGen (brew install xcodegen). Release/notarize also need a
# Developer ID Application cert, a saved notarytool profile, and Sparkle's
# generate_appcast (resolved by SPM — run `make app` once so it exists).
#
# One-time: create the PUBLIC releases repo with an initial commit, e.g.
#   gh repo create jjnicolas/IOS-IPA-Install-releases --public --add-readme

PROJECT  := IOS IPA Install.xcodeproj
SCHEME   := IOS IPA Install
APP_NAME := IOS IPA Install.app
SLUG     := IOS-IPA-Install
DISTDIR  := dist
APP_PRODUCT := $(DISTDIR)/DerivedData/Build/Products/Release/$(APP_NAME)
APP := $(DISTDIR)/$(APP_NAME)

# Signing/notarization inputs — supply on the command line so they stay out of
# the repo, e.g.  make release TEAM=ABCDE12345 NOTARY_PROFILE=my-notary-profile
# TEAM is your Apple Developer Team ID; NOTARY_PROFILE is a notarytool keychain
# profile you've saved locally (xcrun notarytool store-credentials …).
TEAM ?=
NOTARY_PROFILE ?=

# Public releases repo + the latest-asset download prefix that matches SUFeedURL
# (…/IOS-IPA-Install-releases/releases/latest/download/appcast.xml).
RELEASES_GH_REPO ?= jjnicolas/IOS-IPA-Install-releases
DOWNLOAD_URL_PREFIX ?= https://github.com/jjnicolas/IOS-IPA-Install-releases/releases/latest/download/
# generate_appcast ships with Sparkle; SPM drops it in DerivedData once built.
GENERATE_APPCAST := $(shell find $(HOME)/Library/Developer/Xcode/DerivedData -name generate_appcast -path '*sparkle*' 2>/dev/null | head -1)

.PHONY: project app run dist-app notarize release clean

project:
	xcodegen generate

app: project
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" \
		-configuration Debug -destination 'generic/platform=macOS' build

run: app
	open "$$(xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Debug \
		-showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR =/{d=$$3} END{print d}')/$(APP_NAME)"

# Build the Release app (Developer ID + hardened runtime) into ./dist.
# Inject the team so xcodegen fills DEVELOPMENT_TEAM for the Release config.
dist-app:
	@test -n "$(TEAM)" || { echo "Set TEAM=<your Apple Developer Team ID>."; exit 1; }
	DEVELOPMENT_TEAM=$(TEAM) xcodegen generate
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Release \
		-derivedDataPath $(DISTDIR)/DerivedData -destination 'generic/platform=macOS' clean build
	rm -rf "$(APP)"
	cp -R "$(APP_PRODUCT)" "$(APP)"
	@echo "Signed app: $(APP)"

# Notarize and staple the Release app. Requires a stored notarytool profile.
notarize: dist-app
	@test -n "$(NOTARY_PROFILE)" || { echo "Set NOTARY_PROFILE=<your notarytool keychain profile>."; exit 1; }
	ditto -c -k --keepParent "$(APP)" "$(DISTDIR)/$(SLUG).zip"
	xcrun notarytool submit "$(DISTDIR)/$(SLUG).zip" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(APP)"
	@echo "Notarized + stapled: $(APP)"

# Notarize, generate the EdDSA-signed appcast, then publish the versioned zip +
# appcast.xml as assets on the IOS-IPA-Install-releases GitHub release (marked
# --latest, so SUFeedURL resolves to it), and tag this repo vX.Y.
release: notarize
	@test -n "$(GENERATE_APPCAST)" || { echo "generate_appcast not found — run 'make app' once to resolve Sparkle."; exit 1; }
	@command -v gh >/dev/null 2>&1 || { echo "gh CLI required to publish."; exit 1; }
	V=$$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$(APP)/Contents/Info.plist"); \
	REL="$(DISTDIR)/appcast"; rm -rf "$$REL"; mkdir -p "$$REL"; \
	ditto -c -k --keepParent "$(APP)" "$$REL/$(SLUG)-$$V.zip"; \
	NOTES="ReleaseNotes/$$V.html"; \
	if [ -f "$$NOTES" ]; then cp "$$NOTES" "$$REL/$(SLUG)-$$V.html"; fi; \
	"$(GENERATE_APPCAST)" --download-url-prefix "$(DOWNLOAD_URL_PREFIX)" "$$REL"; \
	if gh release view "v$$V" --repo $(RELEASES_GH_REPO) >/dev/null 2>&1; then \
	  gh release upload "v$$V" "$$REL/$(SLUG)-$$V.zip" "$$REL/appcast.xml" --repo $(RELEASES_GH_REPO) --clobber; \
	else \
	  gh release create "v$$V" "$$REL/$(SLUG)-$$V.zip" "$$REL/appcast.xml" \
	    --repo $(RELEASES_GH_REPO) --target main --latest \
	    --title "IOS IPA Install $$V" --notes "IOS IPA Install $$V"; \
	fi; \
	echo "Published IOS IPA Install $$V to $(RELEASES_GH_REPO)."; \
	if git rev-parse -q --verify "refs/tags/v$$V" >/dev/null; then \
	  echo "Tag v$$V already exists in this repo — skipping."; \
	else \
	  git tag -a "v$$V" -m "IOS IPA Install $$V" && git push -q origin "v$$V" && echo "Tagged v$$V."; \
	fi

clean:
	rm -rf "$(PROJECT)" "$(DISTDIR)" DerivedData
