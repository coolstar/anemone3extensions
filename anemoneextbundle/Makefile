ARCHS = arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemoneExtBundle
AnemoneExtBundle_FILES = Tweak.x
AnemoneExtBundle_CFLAGS = -fobjc-arc
AnemoneExtBundle_USE_SUBSTRATE=0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
