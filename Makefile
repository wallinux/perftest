default: help

# Default settings
HOSTNAME	?= $(shell hostname)
USER		?= $(shell whoami)

export SHELL	:= /bin/bash

# Optional configuration specific for this host and user
-include hostconfig-$(HOSTNAME).mk
-include userconfig-$(USER).mk

include tools.mk

WRLVER		?= wrl18
MACHINE		?= native

include $(WRLVER).mk

TOP		:= $(shell pwd)
OUTBASE		?= $(TOP)/out
OUTDIR		= $(OUTBASE)/$(MACHINE)

# Define V=1 to echo everything
V	?= 0
ifneq ($(V),1)
	Q=@
	MFLAGS += -s
endif

include sdk.mk

APPS		+= $(OUTDIR)/bt_perf

APPS_native	+=
CFLAGS_native	=

APPS		+= $(APPS_$(MACHINE))

CFLAGS		+= -O0 -g -ggdb -Wall -rdynamic $(CFLAGS_$(MACHINE)) -frecord-gcc-switches

DEPLOY_DIR	?= test/$(MACHINE)
TARGET_native	?= native
TARGET		?=$(TARGET_$(MACHINE))

#########################################################
.PHONY:: all help

Makefile.help:
	$(call run-help, Makefile)
	$(GREEN)
	$(ECHO) ""
	$(ECHO) " WRLVER   = $(WRLVER)"
	$(ECHO) " MACHINE  = $(MACHINE)"
	$(ECHO) " TARGET   = $(TARGET)"

help:: Makefile.help

all: $(OUTDIR) $(APPS) # build all applications
	$(TRACE)

native: # build native target
	$(TRACE)
	$(MAKE) all MACHINE=native

$(OUTDIR) $(OUTBASE):
	$(TRACE)
	$(MKDIR) -p $@

ifeq ($(BT_PERFTEST),1)
$(OUTDIR)/bt_perf: bt_perf.c Makefile | $(OUTDIR)
	$(TRACE)
	$(info $(MACHINE): building with BT_PERFTEST=$(BT_PERFTEST))
ifeq ($(MACHINE),axxiaarm-prime)
	$(eval cc=arm-wrs-linux-gnueabi-gcc)
	$(eval sysroot=/opt/windriver/wrlinux/wrl18/sysroots/cortexa15t2-neon-wrs-linux-gnueabi)
	$(eval cflags=-march=armv7ve -marm -mthumb-interwork -mfpu=neon -mfloat-abi=softfp -mcpu=cortex-a15)
else ifeq ($(MACHINE),axxiaarm)
	$(eval cc=arm-wrs-linux-gnueabi-gcc)
	$(eval sysroot=/opt/windriver/wrlinux/wrl8/sysroots/cortexa15-vfp-neon-wrs-linux-gnueabi)
	$(eval cflags=-march=armv7-a -mfloat-abi=softfp -mfpu=neon -marm -mthumb-interwork -mtune=cortex-a15)
else ifeq ($(MACHINE),axxiaarm64-prime.32)
	$(eval cc=arm-wrsmllib32-linux-gnueabi-gcc)
	$(eval sysroot=/opt/windriver/wrlinux/wrl18/sysroots//aarch64-wrs-linux)
	$(eval cflags=-march=armv7-a -marm -mfpu=neon -mfloat-abi=softfp)
else ifeq ($(MACHINE),axxiaarm64-ml.32)
	$(eval cc=arm-wrsmllib32-linux-gnueabi-gcc)
	$(eval sysroot=/opt/windriver/wrlinux/wrl8/sysroots//aarch64-wrs-linux)
	$(eval cflags=-march=armv7-a -mfloat-abi=softfp -mfpu=neon -marm -mthumb-interwork)
else
	$(error $MACHINE not supported)
endif
	$(SDK); echo ORIGIN - $@: $$CC $(CFLAGS) $< -o $@
	$(ECHO) UPDATE - $@: $(cc) $(cflags) --sysroot=$(sysroot) $(CFLAGS) $< -o $@
	$(SDK); $(cc) $(cflags) --sysroot=$(sysroot) $(CFLAGS) $< -o $@
else
$(OUTDIR)/bt_perf: bt_perf.c Makefile | $(OUTDIR)
	$(TRACE)
	$(info $(MACHINE): building without BT_PERFTEST=$(BT_PERFTEST))
	$(SDK); echo $@: $$CC $(CFLAGS) $< -o $@
	$(SDK); $$CC $(CFLAGS) $< -o $@
endif

clean:
	$(TRACE)
	$(RM) $(APPS) $(OUTDIR)/*.o

distclean:
	$(TRACE)
	$(RM) -r $(OUTBASE)
	$(RM) *~ \#*#

deploy.scripts:
	$(TRACE)
ifneq ($(TARGET),native)
ifeq ($(V),1)
	$(eval verbose=-v)
endif
	-$(RSYNC) $(verbose) -az scripts $(TARGET):test/
else
	$(ECHO) "do nothing for TARGET=native"
endif

deploy.apps:
	$(TRACE)
ifneq ($(TARGET),native)
ifeq ($(V),1)
	$(eval verbose=-v)
endif
	$(SSH) $(TARGET) mkdir -p $(DEPLOY_DIR)
	-$(RSYNC) $(verbose) -az $(OUTDIR)/* $(TARGET):$(DEPLOY_DIR)
else
	$(ECHO) "do nothing for TARGET=native"
endif

install deploy upload:
	$(TRACE)
	$(MAKE) deploy.scripts
	$(MAKE) deploy.apps

ifeq ($(TARGET),native)
backtrace.test:
	$(TRACE)
	@strings $(OUTDIR)/bt_perf | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q)$(OUTDIR)/bt_perf stop || true

perftest.test:
	$(TRACE)
	$(ECHO) "Must be run with root priviligies"
	$(Q)sudo ./scripts/perftest.all $(MACHINE)

test: backtrace.test perftest.test
	$(TRACE)
endif
