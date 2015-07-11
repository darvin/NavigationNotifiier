TARGET = iphone:clang:latest:8.1
ARCHS = armv7 arm64 armv7s


include theos/makefiles/common.mk

APPLICATION_NAME = NavNotifyCentral
NavNotifyCentral_FILES = main.m NavNotifyCentralApplication.mm RootViewController.mm
NavNotifyCentral_FRAMEWORKS = UIKit CoreGraphics CoreBluetooth
NavNotifyCentral_LIBRARIES = objcipc
include $(THEOS_MAKE_PATH)/application.mk
