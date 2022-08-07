FINALPACKAGE = 1
PACKAGE_VERSION= 1.0

export PKG_VERSION=$(PACKAGE_VERSION)
SUBPROJECTS += source

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk