ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemoneExtFolders
AnemoneExtFolders_FILES = FolderBackground.xm FolderIcons.xm
AnemoneExtFolders_CFLAGS = -fobjc-arc
AnemoneExtFolders_USE_SUBSTRATE=0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
