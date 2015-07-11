include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NavNotifyNowPlaying
NavNotifyNowPlaying_FILES = Tweak.xm
NavNotifyNowPlaying_FRAMEWORKS = UIKit
NavNotifyNowPlaying_LIBRARIES = objcipc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
