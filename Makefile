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

MACHINES	+= axxiaarm
MACHINES	+= axxiaarm-prime
MACHINES	+= axxiaarm64
MACHINES	+= axxiaarm64-prime
MACHINES	+= qemuarm
MACHINES	+= qemuarm64
MACHINE		?= qemuarm

EXTRA_CFLAGS	+= -O0
EXTRA_CFLAGS	+= -g -ggdb
EXTRA_CFLAGS	+= -Wall
EXTRA_CFLAGS	+= -funwind-tables
EXTRA_CFLAGS	+= -fno-omit-frame-pointer
EXTRA_CFLAGS	+= -frecord-gcc-switches
ifdef STATIC
EXTRA_CFLAGS	+= -static
endif

CFLAGS_axxiaarm		+= -mapcs-frame
CFLAGS_axxiaarm-prime	+= -mapcs-frame
CFLAGS_axxiaarm64	+= -mapcs-frame
CFLAGS_axxiaarm64-prime	+=
CFLAGS_qemuarm		+= -mapcs-frame
CFLAGS_qemuarm64	+=

CFLAGS_arm	+= $(EXTRA_CFLAGS) $(CFLAGS_$(MACHINE))
CFLAGS_thumb	+= $(EXTRA_CFLAGS) $(CFLAGS_$(MACHINE))
CFLAGS_arm64	+= $(EXTRA_CFLAGS) $(CFLAGS_$(MACHINE))
CFLAGS_native	+= $(EXTRA_CFLAGS)

SDK_BASE	?= /opt/windriver/wrlinux/wrl18
QEMU_BASE	?= $(SDK_BASE)
PRIME_BASE	?= /opt/windriver/wrlinux/rcs/wrl18

SDK_ENV_axxiaarm-prime	?= $(PRIME_BASE)/environment-setup-cortexa15t2-neon-wrs-linux-gnueabi
#SDK_ENV_axxiaarm64-prime?= $(PRIME_BASE)/environment-setup-armv7at2-neon-wrs-linux-gnueabi
SDK_ENV_axxiaarm64-prime?= $(PRIME_BASE)/environment-setup-armv7at2-neon-wrsmllib32-linux-gnueabi
SDK_ENV_axxiaarm	?= $(SDK_BASE)/environment-setup-cortexa15t2-neon-wrs-linux-gnueabi
SDK_ENV_axxiaarm64	?= $(SDK_BASE)/environment-setup-armv7at2hf-neon-wrsmllib32-linux-gnueabi
SDK_ENV_qemuarm		?= $(QEMU_BASE)/environment-setup-armv5e-wrs-linux-gnueabi
SDK_ENV_qemuarm64	?= $(QEMU_BASE)/environment-setup-armv7at2-neon-wrsmllib32-linux-gnueabi
SDK_ENV			?= $(SDK_ENV_$(MACHINE))

SDK_ENV64_axxiaarm64	?= $(SDK_BASE)/environment-setup-aarch64-wrs-linux
SDK_ENV64_qemuarm64	?= $(QEMU_BASE)/environment-setup-aarch64-wrs-linux
SDK_ENV64		?= $(SDK_ENV64_$(MACHINE))

SDK_ENV_arm		?= $(OUTDIR)/environment_arm
SDK_ENV_arm64		?= $(OUTDIR)/environment_arm64
SDK_ENV_thumb		?= $(OUTDIR)/environment_thumb
SDK_ENV_native		?= $(OUTDIR)/environment_native

CALLGRAPH	?= fp

PERFTEST_ALL	= ./perftest.all

#########################################################
.PHONY:: all help

Makefile.help:
	$(call run-help, Makefile)
	$(GREEN)
	$(ECHO) ""
	$(ECHO) " APPS     = $(APPS)"
	$(ECHO) " SDK_ENV  = $(SDK_ENV)"
	$(ECHO) " MACHINE  = $(MACHINE)"
	$(ECHO) " MACHINES  = $(MACHINES)"
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
	@source $(SDK_ENV_native); echo $@: $$CC $(CFLAGS_native) $< -o $@
	@source $(SDK_ENV_native); $$CC $(CFLAGS_native) $< -o $@

build.native: $(OUTDIR)/bt_perf.native # build test application (native)

backtrace.native: $(OUTDIR)/bt_perf.native # show backtrace
	$(TRACE)
	@strings $< | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q)$< stop || true

perftest.native: $(OUTDIR)/bt_perf.native # run perftest and check stack
	$(TRACE)
	$(ECHO) "Must be run with root privileges"
	$(Q)sudo $(PERFTEST_ALL) native

perftest2.native: $(OUTDIR)/bt_perf.native # run perftest2 and check stack
	$(TRACE)
	$(ECHO) "Must be run with root privileges"
	$(Q)PERFTEST=./perftest2 $(PERFTEST_ALL) native

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
	$(Q)$(PERFTEST_ALL) thumb

perftest2.thumb: # run perftest2 and check stack
	$(TRACE)
	$(Q)PERFTEST=./perftest2 $(PERFTEST_ALL) thumb

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
	$(Q)$(PERFTEST_ALL) arm

perftest2.arm: # run perftest2 and check stack
	$(TRACE)
	$(Q)PERFTEST=./perftest2 $(PERFTEST_ALL) arm

test.arm: backtrace.arm perftest.arm # run arm tests
	$(TRACE)

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
	$(Q)$(PERFTEST_ALL) arm64

perftest2.arm64: # run perftest2 and check stack
	$(TRACE)
	$(Q)PERFTEST=./perftest2 $(PERFTEST_ALL) arm64

test.arm64: backtrace.arm64 perftest.arm64 # run arm64 tests
	$(TRACE)

####################################################################
clean: # clean
	$(TRACE)
	$(RM) $(APPS)

distclean: # distclean
	$(TRACE)
	$(RM) -r $(OUTDIR)
	$(RM) *~ \#*#

####################################################################
SSHPORT_axxiaarm	?= 22
SSHPORT_axxiaarm-prime	?= 22
SSHPORT_axxiaarm64	?= 22
SSHPORT_axxiaarm64-prime?= 22
SSHPORT_qemuarm		?= 2222
SSHPORT_qemuarm64	?= 2222
SSHPORT			?= $(SSHPORT_$(MACHINE))

TARGET_axxiaarm		?= ama1
TARGET_axxiaarm-prime	?= ama1
TARGET_axxiaarm64	?= vic2
TARGET_axxiaarm64-prime	?= vic2
TARGET_qemuarm		?= localhost
TARGET_qemuarm64	?= localhost
TARGET			?= $(TARGET_$(MACHINE))

TARGET_USER		?= root
SSHOPTS			+= -o StrictHostKeyChecking=no
SSHOPTS			+= -o UserKnownHostsFile=/dev/null

SSHTARGET		= $(SSH) $(SSHOPTS) $(TARGET_USER)@$(TARGET) -p $(SSHPORT)

target.sync: # cp files to target
	$(TRACE)
	$(SSHTARGET) "mkdir -p perftest"
	$(SCP) $(SSHOPTS) -q -r -P $(SSHPORT) perftest* Makefile tools.mk out $(TARGET_USER)@$(TARGET):perftest/

target.get: # cp files from target
	$(TRACE)
	$(MKDIR) $(TARGET)
#	$(SCP) $(SSHOPTS) -q -r -P $(SSHPORT) $(TARGET_USER)@$(TARGET):/root $(TARGET)/
	$(RSYNC) -az -e "ssh -p $(SSHPORT) $(SSHOPTS)" $(TARGET_USER)@$(TARGET):/root $(TARGET)

target.ssh: # ssh to target
	$(TRACE)
	$(SSHTARGET)

target.test.thumb: # run thumb test on target
	$(TRACE)
	$(SSHTARGET) make -s -C perftest test.thumb

target.test.arm: # run arm test on target
	$(TRACE)
	$(SSHTARGET) make -s -C perftest test.arm

target.all:: build.arm build.thumb
	$(TRACE)
	$(MAKE) target.sync
	-$(SSHTARGET) CALLGRAPH=$(CALLGRAPH) make -s -C perftest perftest.arm   MACHINE=$(MACHINE)
	-$(SSHTARGET) CALLGRAPH=$(CALLGRAPH) make -s -C perftest perftest.thumb MACHINE=$(MACHINE)

target.test.arm64: # run arm64 test on target
	$(TRACE)
	$(SSHTARGET) make -s -C perftest test.arm64

target64.all: build.arm64
	$(TRACE)
	$(MAKE) -s target.sync
	-$(SSHTARGET) CALLGRAPH=$(CALLGRAPH) make -s -C perftest perftest.arm64 MACHINE=$(MACHINE)
