ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pueue
PUEUE_COMMIT  := e7eb5150a36bcfbc8774715964d1e3ef1e407113
PUEUE_VERSION := 0~20210420.$(shell echo $(PUEUE_COMMIT) | cut -c -7)
DEB_PUEUE_V   := $(PUEUE_VERSION)
USER_HOME          := $(shell echo $$HOME)

pueue-setup: setup
	$(call GITHUB_ARCHIVE,Nukesor,pueue,$(PUEUE_COMMIT),$(PUEUE_COMMIT))
	$(call EXTRACT_TAR,pueue-$(PUEUE_COMMIT).tar.gz,pueue-$(PUEUE_COMMIT),pueue)

ifneq ($(wildcard $(BUILD_WORK)/pueue/.build_complete),)
pueue:
	@echo "Using previously built pueue."
else
pueue: pueue-setup
 	### initial build, intended to fail so it can be patched
	$(SED) -i 's|#[cfg(target_os = "macos")]|#[cfg(any(target_os = "macos", target_os = "ios"))]|g' '$(USER_HOME)/.cargo/registry/src/github.com-1ecc6299db9ec823/pueue-lib-0.12.2/src/platform/mod.rs'
	$(SED) -i 's|#[cfg(target_os = "macos")]|#[cfg(any(target_os = "macos", target_os = "ios"))]|g' $(BUILD_WORK)/pueue/daemon/platform/mod.rs
	cd $(BUILD_WORK)/pueue && unset CFLAGS && SDKROOT="$(TARGET_SYSROOT)" cargo install \
		--target=$(RUST_TARGET) \
		--root $(BUILD_STAGE)/pueue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/ \
		--path . \
		--offline
		touch $(BUILD_WORK)/pueue/.build_complete
endif

pueue-package: pueue-stage
	# pueue.mk Package Structure
	rm -rf $(BUILD_DIST)/pueue
	mkdir -p $(BUILD_DIST)/pueue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/pueue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Library/LaunchDaemons/

	# pueue.mk Prep pueue
	cp -a $(BUILD_STAGE)/pueue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ $(BUILD_DIST)/pueue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_INFO)/com.nukesor.pueued.plist $(BUILD_DIST)/pueue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Library/LaunchDaemons/
	
	for file in $(BUILD_DIST)/pueue$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/Library/LaunchDaemons/* ; do \
		$(SED) -i 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' $$file; \
		$(SED) -i 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' $$file; \
	done
	# pueue.mk Sign
	$(call SIGN,pueue,general.xml)

	# pueue.mk Make .debs
	$(call PACK,pueue,DEB_PUEUE_V)

	# pueue.mk Build cleanup

.PHONY: pueue pueue-package
