# -*- mode: Makefile; -*-

## -----------------------------------------------------------------------------
## --SECTION--                                                    COMMON DEFINES
## -----------------------------------------------------------------------------

NAME = ArangoDB
VERSION = 1.4.1

SOURCE_FILES = build/ArangoDB.app ArangoDB/CHANGELOG ArangoDB/README

MASTER_DMG = $(NAME)-$(VERSION).dmg
WC_DMG = build/wc.dmg
WC_DIR = build/wc

.PHONY: all
all: standalone

## -----------------------------------------------------------------------------
## --SECTION--                                                        STANDALONE
## -----------------------------------------------------------------------------

.PHONY: standalone
standalone:
	rm -rf build
	mkdir build

	@echo
	@echo --------------------- Building ArangoDB --------------------

	cd ArangoDB/Build && make DESTDIR=../../build install

	@echo
	@echo --------------------- Building Standalone --------------------

	xcodebuild -target 'Standalone' -archivePath build/archive -scheme "ArangoDB Standalone" archive
	mv build/archive.xcarchive/Products/Applications/ArangoDB.app build

	make $(MASTER_DMG)


$(MASTER_DMG): $(SOURCE_FILES)
	@echo
	@echo --------------------- Generating empty template --------------------

	mkdir template
	hdiutil create -fs HFSX -layout SPUD -size 500m "$(WC_DMG)" -srcfolder template -format UDRW -volname "$(NAME)" -quiet
	rmdir template

	@echo
	@echo --------------------- Creating Disk Image --------------------

	mkdir -p $(WC_DIR)
	hdiutil attach "$(WC_DMG)" -noautoopen -quiet -mountpoint "$(WC_DIR)"

	for i in $(SOURCE_FILES); do  \
		rm -rf "$(WC_DIR)/`basename $$i`"; \
		ditto -rsrc "$$i" "$(WC_DIR)/`basename $$i`"; \
	done

	ln -s /Applications "$(WC_DIR)/Applications"

	WC_DEV=`hdiutil info | grep "$(WC_DIR)" | grep "Apple_HFS" | awk '{print $$1}'` \
	  && hdiutil detach $$WC_DEV -quiet -force

	rm -f "$(MASTER_DMG)"
	hdiutil convert "$(WC_DMG)" -quiet -format UDZO -imagekey zlib-level=9 -o "$@"
	rm -rf $(WC_DIR)
	@echo

## -----------------------------------------------------------------------------
## --SECTION--                                                             CLEAN
## -----------------------------------------------------------------------------

.PHONY: clean
clean:
	-rm -rf $(MASTER_DMG) $(WC_DMG)

## -----------------------------------------------------------------------------
## --SECTION--                                                       END-OF-FILE
## -----------------------------------------------------------------------------

## Local Variables:
## mode: outline-minor
## outline-regexp: "^\\(### @brief\\|## --SECTION--\\|# -\\*- \\)"
## End: