ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemoneExt
AnemoneExt_FILES = Badges.xm PageDots.xm
AnemoneExt_CFLAGS = -fobjc-arc
AnemoneExt_USE_SUBSTRATE=0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
#SUBPROJECTS += anemoneextbundle
SUBPROJECTS += anemoneextfolders
SUBPROJECTS += anemoneextdock
include $(THEOS_MAKE_PATH)/aggregate.mk
