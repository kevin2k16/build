#=============================================================================
# BASIC ENVIRONMENT SETUP

# this turns off the suffix rules built into make
.SUFFIXES:

# this turns off the RCS / SCCS implicit rules of GNU Make
% : RCS/%,v
% : RCS/%
% : %,v
% : s.%
% : SCCS/s.%

# If a rule fails, delete $@.
.DELETE_ON_ERROR:

# Absolute path of the present working direcotry.
# This overrides the shell variable $PWD, which does not necessarily points to
# the top of the source tree, for example when "make -C" is used in m/mm/mmm.
PWD := $(shell pwd)

TOP := .
TOPDIR :=

BUILD_SYSTEM := $(TOPDIR)build/core

# This is the default target.  It must be the first declared target.
.PHONY: all
DEFAULT_GOAL := all
$(DEFAULT_GOAL):

# verfiy device name
DEVICE_NAME = $(firstword $(MAKECMDGOALS))
HOST_ONLY = 0
ifeq ($(DEVICE_NAME),)
$(error No device specified.  Use "make devicename")
endif

ifeq ($(DEVICE_NAME),host)
HOST_ONLY = 1
else
ifeq ($(wildcard build/devices/$(DEVICE_NAME)/device.mk),)
$(error $(DEVICE_NAME) is not a valid device.)
endif
endif # DEVICE_NAME

# src paths
CONFIG_DIR = $(TOPDIR)build/config
PREBUILTS_DIR = $(TOPDIR)prebuilts

# build paths
OUT_DIR = $(TOPDIR)out
TARGET_OUT = $(OUT_DIR)/target/$(DEVICE_NAME)
TARGET_COMMON_OUT = $(OUT_DIR)/target/common
HOST_OUT = $(OUT_DIR)/host

# toolchain
TOOLCHAIN_LINUX_GNUEABIHF = $(PREBUILTS_DIR)/gcc/linux-x86/arm/arm-linux-gnueabihf-4.9
TOOLCHAIN_LINUX_GNUEABIHF_HOST = arm-linux-gnueabihf
TOOLCHAIN_LINUX_GNUEABIHF_LIBC = $(TOOLCHAIN_LINUX_GNUEABIHF)/$(TOOLCHAIN_LINUX_GNUEABIHF_HOST)/libc

TOOLCHAIN_NONE_EABI = $(PREBUILTS_DIR)/gcc/linux-x86/arm/arm-eabi-4.8
TOOLCHAIN_NONE_EABI_PREFIX = $(PWD)/$(TOOLCHAIN_NONE_EABI)/bin/arm-eabi-
ARM_CROSS_COMPILE = ARCH=arm SUBARCH=arm CROSS_COMPILE=$(TOOLCHAIN_NONE_EABI_PREFIX) TOOLCHAIN_PREFIX=$$CROSS_COMPILE ARCH_arm_TOOLCHAIN_PREFIX=$$CROSS_COMPILE

# create out directories
$(shell mkdir -p $(OUT_DIR))
$(shell mkdir -p $(TARGET_OUT))
$(shell mkdir -p $(TARGET_COMMON_OUT))
$(shell mkdir -p $(HOST_OUT))

# cleanup targets
CLEAN_TARGETS =
DISTCLEAN_TARGETS =

# shell
SHELL := /bin/bash
PATH := $(PWD)/$(TOOLCHAIN_LINUX_GNUEABIHF)/bin:$(PATH)
PATH := $(PWD)/$(TOOLCHAIN_NONE_EABI)/bin:$(PATH)


#=============================================================================
# DEVICES

ifneq ($(HOST_ONLY),1)
include $(TOPDIR)build/devices/$(DEVICE_NAME)/device.mk

# generate build targets
BUILD_TARGETS = grub_boot_fs
ifeq ($(ENABLE_2NDSTAGE_BOOT),1)
BUILD_TARGETS += lk_bootimg
else
BUILD_TARGETS += lk
endif

# main build target
build: $(BUILD_TARGETS)
.PHONY : $(BUILD_TARGETS)

# build targets selected via cmdline or "build"
ifeq ($(DEVICE_NAME),$(MAKECMDGOALS))
$(DEVICE_NAME): build
.PHONY : $(DEVICE_NAME)
else
$(DEVICE_NAME):
.PHONY : $(DEVICE_NAME)
endif

else
$(DEVICE_NAME):
.PHONY : $(DEVICE_NAME)
endif # !HOST_ONLY


#=============================================================================
# TASKS

ifneq ($(HOST_ONLY),1)
include $(TOPDIR)build/core/tasks/*.mk
endif


#=============================================================================
# HOST TOOLS

include $(TOPDIR)build/host/*.mk


#=============================================================================
# CLEANUP

clean: $(CLEAN_TARGETS)
.PHONY : clean

distclean: $(DISTCLEAN_TARGETS)
	rm -Rf $(OUT_DIR)
.PHONY : distclean
