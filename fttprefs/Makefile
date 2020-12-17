include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = fttprefs

export ARCHS = armv7 arm64 arm64e

fttprefs_FILES = ttrRootListController.m
fttprefs_INSTALL_PATH = /Library/PreferenceBundles
fttprefs_FRAMEWORKS = UIKit
fttprefs_PRIVATE_FRAMEWORKS = Preferences
fttprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/fttprefs.plist$(ECHO_END)
