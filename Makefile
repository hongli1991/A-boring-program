APP_NAME := CONTROL
BUNDLE_ID := com.codex.control
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/Payload/$(APP_NAME).app
SDK ?= iphoneos
MIN_IOS := 14.0
CC := xcrun -sdk $(SDK) clang
CFLAGS := -arch arm64 -miphoneos-version-min=$(MIN_IOS) -fobjc-arc -fmodules -I Sources -Wall -Wextra
LDFLAGS_APP := -framework UIKit -framework Foundation -framework CoreFoundation -framework IOKit
LDFLAGS_HELPER := -framework Foundation -framework CoreFoundation -framework IOKit
COMMON_C := Sources/CTBattery.c Sources/CTChargePolicy.c Sources/CTCPU.c Sources/CTDisplay.c
APP_SRC := Sources/main.m Sources/AppDelegate.m Sources/ControlRootViewController.m Sources/CTRoot.c $(COMMON_C)
HELPER_SRC := Helper/main.c $(COMMON_C)

.PHONY: all app helper package clean sign

all: package

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

app: $(BUILD_DIR)
	mkdir -p $(APP_DIR)
	$(CC) $(CFLAGS) $(APP_SRC) $(LDFLAGS_APP) -o $(APP_DIR)/$(APP_NAME)
	cp Info.plist $(APP_DIR)/Info.plist

helper: $(BUILD_DIR)
	mkdir -p $(APP_DIR)
	$(CC) $(CFLAGS) $(HELPER_SRC) $(LDFLAGS_HELPER) -o $(APP_DIR)/control-helper

sign: app helper
	ldid -Scontrol.entitlements $(APP_DIR)/$(APP_NAME)
	ldid -Scontrol.entitlements $(APP_DIR)/control-helper

package: sign
	cd $(BUILD_DIR) && zip -qry ../$(APP_NAME).tipa Payload

clean:
	rm -rf $(BUILD_DIR) $(APP_NAME).tipa
