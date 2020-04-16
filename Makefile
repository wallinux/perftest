default: help

# Default settings
HOSTNAME	?= $(shell hostname)
USER		?= $(shell whoami)

export SHELL	:= /bin/bash

# Optional configuration specific for this host and user
-include hostconfig-$(HOSTNAME).mk
-include userconfig-$(USER).mk

include tools.mk

TOP		:= $(shell pwd)
OUTDIR		?= $(TOP)/out

APPS		+=  $(OUTDIR)/bt_perf.native
APPS		+=  $(OUTDIR)/bt_perf.arm
APPS		+=  $(OUTDIR)/bt_perf.thumb
ifneq (,$(filter $(MACHINE),axxiaarm64 qemuarm64))
APPS	+=  $(OUTDIR)/bt_perf.arm64
endif

CFLAGS_X	+= -O0
CFLAGS_X	+= -g -ggdb
CFLAGS_X	+= -Wall
CFLAGS_X	+= -funwind-tables
CFLAGS_X	+= -fno-omit-frame-pointer
CFLAGS_X	+= -frecord-gcc-switches
ifdef STATIC
CFLAGS_X	+= -static
endif
CFLAGS_arm	+= $(CFLAGS_X) -mapcs-frame
CFLAGS_thumb	+= $(CFLAGS_X) -mapcs-frame
CFLAGS_arm64	+= $(CFLAGS_X)

MACHINE		?= axxiaarm

SDK_BASE	?= /opt/windriver/wrlinux/wrl18
QEMU_BASE	?= $(SDK_BASE)

SDK_ENV_axxiaarm   ?= $(SDK_BASE)/environment-setup-cortexa15t2-neon-wrs-linux-gnueabi
SDK_ENV_axxiaarm64 ?= $(SDK_BASE)/environment-setup-armv7at2hf-neon-wrsmllib32-linux-gnueabi
SDK_ENV_qemuarm    ?= $(QEMU_BASE)/environment-setup-armv5e-wrs-linux-gnueabi
SDK_ENV_qemuarm64  ?= $(QEMU_BASE)/environment-setup-armv7at2-neon-wrsmllib32-linux-gnueabi
SDK_ENV		   ?= $(SDK_ENV_$(MACHINE))

SDK_ENV64_axxiaarm64 ?= $(SDK_BASE)/environment-setup-aarch64-wrs-linux
SDK_ENV64_qemuarm64  ?= $(QEMU_BASE)/environment-setup-aarch64-wrs-linux
SDK_ENV64	     ?= $(SDK_ENV64_$(MACHINE))

SDK_ENV_arm	?= $(OUTDIR)/environment_arm
SDK_ENV_arm64	?= $(OUTDIR)/environment_arm64
SDK_ENV_thumb	?= $(OUTDIR)/environment_thumb
SDK_ENV_native	?= $(OUTDIR)/environment_native

CALLGRAPH	?= fp

#########################################################
.PHONY:: all help

Makefile.help:
	$(call run-help, Makefile)
	$(GREEN)
	$(ECHO) ""
	$(ECHO) " APPS     = $(APPS)"
	$(ECHO) " SDK_ENV  = $(SDK_ENV)"
	$(NORMAL)

help:: Makefile.help

all: $(OUTDIR) $(APPS) # build all applications
	$(TRACE)

$(OUTDIR):
	$(TRACE)
	$(MKDIR) $@

####################################################################
$(SDK_ENV_native): | $(OUTDIR)
	$(TRACE)
	$(ECHO) "export CC=gcc" > $@

$(OUTDIR)/bt_perf.native: bt_perf.c Makefile $(SDK_ENV_native) | $(OUTDIR)
	$(TRACE)
	$(ECHO) -----------------------
	@source $(SDK_ENV_native); echo $@: $$CC $(CFLAGS_X) $< -o $@
	@source $(SDK_ENV_native); $$CC $(CFLAGS_X) $< -o $@

build.native: $(OUTDIR)/bt_perf.native # build test application (native)

backtrace.native: $(OUTDIR)/bt_perf.native # show backtrace
	$(TRACE)
	@strings $< | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q)$< stop || true

perftest.native: $(OUTDIR)/bt_perf.native # run perftest and check stack
	$(TRACE)
	$(ECHO) "Must be run with root privileges"
	$(Q)sudo ./perftest.all native

perftest2.native: $(OUTDIR)/bt_perf.native # run perftest2 and check stack
	$(TRACE)
	$(ECHO) "Must be run with root privileges"
	$(Q)PERFTEST=./perftest2 sudo ./perftest.all native

test.native: backtrace.native perftest.native # run native tests
	$(TRACE)

####################################################################
$(SDK_ENV_thumb): $(SDK_ENV) | $(OUTDIR)
	$(TRACE)
	$(CP) $< $@

$(OUTDIR)/bt_perf.thumb: bt_perf.c Makefile $(SDK_ENV_thumb)| $(OUTDIR)
	$(TRACE)
	$(ECHO) -----------------------
	@source $(SDK_ENV_thumb); echo $@: $$CC $(CFLAGS_thumb) $< -o $@
	@source $(SDK_ENV_thumb); $$CC $(CFLAGS_thumb) $< -o $@

build.thumb: $(OUTDIR)/bt_perf.thumb # build test application (thumb)

backtrace.thumb: # show backtrace
	$(TRACE)
	@strings $(OUTDIR)/bt_perf.thumb | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q)$(OUTDIR)/bt_perf.thumb stop || true

perftest.thumb: # run perftest and check stack
	$(TRACE)
	$(Q)./perftest.all thumb

perftest2.thumb: # run perftest2 and check stack
	$(TRACE)
	$(Q)PERFTEST=./perftest2 ./perftest.all thumb

test.thumb: backtrace.thumb perftest.thumb  # run thumb tests
	$(TRACE)

####################################################################
$(SDK_ENV_arm): $(SDK_ENV) | $(OUTDIR)
	$(TRACE)
	$(CP) $< $@
	$(SED) 's/mthumb/marm/' $@

$(OUTDIR)/bt_perf.arm: bt_perf.c Makefile $(SDK_ENV_arm) | $(OUTDIR)
	$(TRACE)
	$(ECHO) -----------------------
	@source $(SDK_ENV_arm); echo $@: $$CC $(CFLAGS_arm) $< -o $@
	@source $(SDK_ENV_arm); $$CC $(CFLAGS_arm) $< -o $@

build.arm: $(OUTDIR)/bt_perf.arm # build test application (arm)

backtrace.arm: # show backtrace
	$(TRACE)
	@strings  $(OUTDIR)/bt_perf.arm | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q) $(OUTDIR)/bt_perf.arm stop || true

perftest.arm: # run perftest and check stack
	$(TRACE)
	$(Q)./perftest.all arm

perftest2.arm: # run perftest2 and check stack
	$(TRACE)
	$(Q)PERFTEST=./perftest2 ./perftest.all arm

test.arm: backtrace.arm perftest.arm # run arm tests
	$(TRACE)

ifneq (,$(filter $(MACHINE),axxiaarm64 qemuarm64))
####################################################################
$(SDK_ENV_arm64): $(SDK_ENV64) | $(OUTDIR)
	$(TRACE)
	$(CP) $< $@

$(OUTDIR)/bt_perf.arm64: bt_perf.c Makefile $(SDK_ENV_arm64) | $(OUTDIR)
	$(TRACE)
	$(ECHO) -----------------------
	@source $(SDK_ENV_arm64); echo $@: $$CC $(CFLAGS_arm64) $< -o $@
	@source $(SDK_ENV_arm64); $$CC $(CFLAGS_arm64) $< -o $@

build.arm64: $(OUTDIR)/bt_perf.arm64 # build test application (arm64)

backtrace.arm64: # show backtrace
	$(TRACE)
	@strings  $(OUTDIR)/bt_perf.arm64 | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q) $(OUTDIR)/bt_perf.arm64 stop || true

perftest.arm64: # run perftest and check stack
	$(TRACE)
	$(Q)./perftest.all arm64

perftest2.arm64: # run perftest2 and check stack
	$(TRACE)
	$(Q)PERFTEST=./perftest2 ./perftest.all arm64

test.arm64: backtrace.arm64 perftest.arm64 # run arm64 tests
	$(TRACE)

APPS	+=  $(OUTDIR)/bt_perf.arm64
endif
####################################################################
clean: # clean
	$(TRACE)
	$(RM) $(APPS)

distclean: # distclean
	$(TRACE)
	$(RM) -r $(OUTDIR)
	$(RM) *~ \#*#

####################################################################
TARGET_IP ?= 128.224.95.181

target.sync: # cp files to target
	$(TRACE)
	$(RSYNC) -az --exclude=.* --exclude=*~ --exclude=#* --exclude=*native* --exclude=.git \
		. root@$(TARGET_IP):perftest/

target.ssh: # ssh to target
	$(TRACE)
	$(SSH) root@$(TARGET_IP)

target.test.thumb: # run thumb test on target
	$(TRACE)
	$(SSH) root@$(TARGET_IP) make -s -C perftest test.thumb

target.test.arm: # run arm test on target
	$(TRACE)
	$(SSH) root@$(TARGET_IP) make -s -C perftest test.arm

target.all:: build.arm build.thumb
	$(TRACE)
	$(MAKE) -s target.sync
	-$(SSH) root@$(TARGET_IP) CALLGRAPH=$(CALLGRAPH) make -s -C perftest perftest.arm    MACHINE=$(MACHINE)
	-$(SSH) root@$(TARGET_IP) CALLGRAPH=$(CALLGRAPH) make -s -C perftest perftest.thumb  MACHINE=$(MACHINE)

ifneq (,$(filter $(MACHINE),axxiaarm64 qemuarm64))
target.test.arm64: # run arm64 test on target
	$(TRACE)
	$(SSH) root@$(TARGET_IP) make -s -C perftest test.arm64

target64.all: build.arm64
	$(TRACE)
	$(MAKE) -s target.sync
	-$(SSH) root@$(TARGET_IP) CALLGRAPH=$(CALLGRAPH) make -s -C perftest perftest.arm64  MACHINE=$(MACHINE)

target.all:: target64.all
endif

