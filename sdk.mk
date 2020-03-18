#!/bin/bash

SDK_URL				?= http://arn-build3.wrs.com:7777
SDK_BASE			?= /opt/windriver/wrlinux/rcs/$(WRLVER)
SDK_DLDIR			?= /opt/windriver/wrlinux/rcs/sdks

SDK_ENV_native			?= $(TOP)/environment_native
SDK_ENV  			= $(SDK_ENV_$(MACHINE))
SDK 				:= @source $(SDK_ENV)

$(SDK_DLDIR):
	$(TRACE)
	$(MKDIR) -p $@

ifeq ($(WRLVER), wrl18)
sdk.get: $(SDK_DLDIR) # get sdk from $(SDK_URL) 
	$(TRACE)
	$(Q)wget -N -r -nH --cut-dirs=10 --no-parent -A '.sh' -P $< $(SDK_URL)/release/wrlinux/$(DISTRO_VERSION)/$(MACHINE)/sdk/
	$(CHMOD) +x $</*.sh
else
sdk.get:
	$(TRACE)
	$(ECHO) NOT IMPLEMENTED FOR WRLINUX 8
endif

sdk.install: # install sdk
	$(TRACE)
	$(eval sdk_file=$(shell realpath $(SDK_DLDIR)/*$(subst -,_,$(MACHINE))-*.sh))
	$(Q)$(sdk_file) -y -d $(SDK_BASE)

sdk.help:
	$(call run-help, sdk.mk)
	$(GREEN)
	$(ECHO) ""
	$(ECHO) " SDK_URL   = $(SDK_URL)"
	$(ECHO) " SDK_DLDIR = $(SDK_DLDIR)"
	$(ECHO) " SDK_ENV   = $(SDK_ENV)"
ifeq ($(V),1)
	$(SDK); echo " CC        = $$CC"; $$CC --version;
	$(SDK); echo " CFLAGS    = $(CFLAGS)"
endif

help:: sdk.help
