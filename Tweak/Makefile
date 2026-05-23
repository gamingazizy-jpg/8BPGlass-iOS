TARGET := iphone:clang:latest:10.0
INSTALL_TARGET_PROCESSES = pool

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EightBPGlass
EightBPGlass_FILES = Tweak.xm ../Native/PredictionEngine.mm
EightBPGlass_CFLAGS = -fobjc-arc -std=c++17 -I../Native -I../Native/Vector
EightBPGlass_LDFLAGS = -lsubstrate -lobjc

include $(THEOS_MAKE_PATH)/tweak.mk
