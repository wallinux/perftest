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

CFLAGS_X	+= -O0
CFLAGS_X	+= -g -ggdb
CFLAGS_X	+= -Wall
CFLAGS_X	+= -funwind-tables
CFLAGS_X	+= -fno-omit-frame-pointer
CFLAGS_X	+= -frecord-gcc-switches
CFLAGS_arm	+= $(CFLAGS_X) -mapcs-frame
CFLAGS_thumb	+= $(CFLAGS_X) -mapcs-frame

SDK_BASE	?= /opt/windriver/wrlinux/wrl18
SDK_ENV_axxiaarm?= $(SDK_BASE)/environment-setup-cortexa15t2-neon-wrs-linux-gnueabi
SDK_ENV_arm	?= $(OUTDIR)/environment_arm
SDK_ENV_thumb	?= $(OUTDIR)/environment_thumb
SDK_ENV_native	?= $(OUTDIR)/environment_native

#########################################################
.PHONY:: all help

Makefile.help:
	$(call run-help, Makefile)
	$(GREEN)
	$(ECHO) ""
	$(ECHO) " APPS  = $(APPS)"

help:: Makefile.help

all: $(OUTDIR) $(APPS) # build all applications
	$(TRACE)

$(OUTDIR):
	$(TRACE)
	$(MKDIR) -p $@

####################################################################
$(SDK_ENV_native): | $(OUTDIR)
	$(TRACE)
	$(ECHO) "export CC=gcc" > $@

$(OUTDIR)/bt_perf.native: bt_perf.c Makefile $(SDK_ENV_native) | $(OUTDIR)
	$(TRACE)
	$(ECHO) -----------------------
	@source $(SDK_ENV_native); echo $@: $$CC $(CFLAGS_X) $< -o $@
	@source $(SDK_ENV_native); $$CC $(CFLAGS_X) $< -o $@

backtrace.native: $(OUTDIR)/bt_perf.native # show backtrace
	$(TRACE)
	@strings $< | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q)$< stop || true

perftest.native: $(OUTDIR)/bt_perf.native # run perftest and check stack
	$(TRACE)
	$(ECHO) "Must be run with root priviligies"
	$(Q)sudo ./perftest.all native

test.native: backtrace.native perftest.native # run native tests
	$(TRACE)

####################################################################
$(SDK_ENV_thumb): $(SDK_ENV_axxiaarm) | $(OUTDIR)
	$(TRACE)
	$(CP) $< $@

$(OUTDIR)/bt_perf.thumb: bt_perf.c Makefile $(SDK_ENV_thumb)| $(OUTDIR)
	$(TRACE)
	$(ECHO) -----------------------
	@source $(SDK_ENV_thumb); echo $@: $$CC $(CFLAGS_thumb) $< -o $@
	@source $(SDK_ENV_thumb); $$CC $(CFLAGS_thumb) $< -o $@

backtrace.thumb: # show backtrace
	$(TRACE)
	@strings $(OUTDIR)/bt_perf.thumb | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q)$(OUTDIR)/bt_perf.thumb stop || true

perftest.thumb: # run perftest and check stack
	$(TRACE)
	$(ECHO) "Must be run with root priviligies"
	$(Q)sudo ./perftest.all thumb

test.thumb: backtrace.thumb perftest.thumb  # run thumb tests
	$(TRACE)

####################################################################
$(SDK_ENV_arm): $(SDK_ENV_axxiaarm) | $(OUTDIR)
	$(TRACE)
	$(CP) $< $@
	$(SED) 's/mthumb/marm/' $@

$(OUTDIR)/bt_perf.arm: bt_perf.c Makefile $(SDK_ENV_arm) | $(OUTDIR)
	$(TRACE)
	$(ECHO) -----------------------
	@source $(SDK_ENV_arm); echo $@: $$CC $(CFLAGS_arm) $< -o $@
	@source $(SDK_ENV_arm); $$CC $(CFLAGS_arm) $< -o $@

backtrace.arm: # show backtrace
	$(TRACE)
	@strings  $(OUTDIR)/bt_perf.arm | sed -n '/GCC:/,/frecord-gcc-switches/p' | tr '\n' ' '
	$(ECHO) ""
	$(Q) $(OUTDIR)/bt_perf.arm stop || true

perftest.arm: # run perftest and check stack
	$(TRACE)
	$(ECHO) "Must be run with root priviligies"
	$(Q)sudo ./perftest.all arm

test.arm: backtrace.arm perftest.arm # run arm tests
	$(TRACE)

####################################################################
clean: # clean
	$(TRACE)
	$(RM) $(APPS)

distclean: # distclean
	$(TRACE)
	$(RM) -r $(OUTDIR)
	$(RM) *~ \#*#
