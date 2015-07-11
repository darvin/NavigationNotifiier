include theos/makefiles/common.mk

TWEAK_NAME = NavNotifySpringBoardCentral
NavNotifySpringBoardCentral_FILES = Tweak.xm
NavNotifySpringBoardCentral_LIBRARIES = objcipc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
