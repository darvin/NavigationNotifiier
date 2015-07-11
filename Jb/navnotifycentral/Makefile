# export ARCHS = armv7
# export TARGET = iphone:clang:7.1:7.1

include theos/makefiles/common.mk

APPLICATION_NAME = NavNotifyCentral
NavNotifyCentral_FILES = main.m NavNotifyCentralApplication.mm RootViewController.mm
NavNotifyCentral_FRAMEWORKS = UIKit CoreGraphics CoreFoundation CoreBluetooth
NavNotifyCentral_LIBRARIES = objcipc
include $(THEOS_MAKE_PATH)/application.mk
