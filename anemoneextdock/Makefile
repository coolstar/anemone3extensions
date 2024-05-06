TARGET=iphone:clang:latest:11.0
ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemoneExtDock
AnemoneExtDock_FILES = Dock.xm DockBackground.xm UIImage+GaussianBlur.mm
AnemoneExtDock_CFLAGS = -fobjc-arc
AnemoneExtDock_USE_SUBSTRATE=0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
