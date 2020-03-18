amarillo_1.%: TARGET=amarillo_1

amarillo_1.build: # build and deploy wrl8 and wrl18 target to amarillo_1
	$(TRACE)
	$(MAKE) distclean
	$(SSH)  $(TARGET) rm -rf test
	$(MAKE) WRLVER=wrl8  MACHINE=axxiaarm       bt_perf deploy.apps
	$(MAKE) WRLVER=wrl18 MACHINE=axxiaarm-prime bt_perf deploy.apps
	$(SSH)  $(TARGET) mv test/axxiaarm-prime test/axxiaarm-prime.thumb
	$(MAKE) WRLVER=wrl18 MACHINE=axxiaarm-prime BT_PERFTEST=1 clean bt_perf deploy.apps
	$(SSH)  $(TARGET) mv test/axxiaarm-prime test/axxiaarm-prime.arm
	$(MAKE) TARGET=$(TARGET) deploy.scripts

ama1 amarillo_1: amarillo_1.build

victoria_2.%: TARGET=victoria_2
victoria_2.build : # build and deploy wrl8 and wrl18 target to victoria_2
	$(TRACE)
	$(MAKE) distclean
	$(SSH)  $(TARGET) rm -rf test
	$(MAKE) WRLVER=wrl8  MACHINE=axxiaarm64-ml.32    bt_perf deploy.apps
	$(MAKE) WRLVER=wrl18 MACHINE=axxiaarm64-prime.32 bt_perf deploy.apps
	$(SSH)  $(TARGET) mv test/axxiaarm64-prime.32 test/axxiaarm64-prime.32.thumb
	$(MAKE) WRLVER=wrl18 MACHINE=axxiaarm64-prime.32 BT_PERFTEST=1 clean bt_perf deploy.apps
	$(SSH)  $(TARGET) mv test/axxiaarm64-prime.32 test/axxiaarm64-prime.32.arm
	$(MAKE) TARGET=$(TARGET) deploy.scripts

vic2 victoria_2: victoria_2.build

victoria_2.64: # build and deploy 64 bite wrl8 and wrl18 target to victoria_2
	$(TRACE)
	$(MAKE) TARGET=victoria_2 WRLVER=wrl8  MACHINE=axxiaarm64-ml       all deploy
	$(MAKE) TARGET=victoria_2 WRLVER=wrl18 MACHINE=axxiaarm64-prime    all deploy

victoria_2.test amarillo_1.test:
	$(SSH) $(TARGET) /root/test/scripts/backtrace.all
	$(SSH) $(TARGET) /root/test/scripts/perftest.all

ama1.all:
	$(TRACE)
	$(MAKE) amarillo_1.build
	$(MAKE) amarillo_1.test

vic2.all:
	$(TRACE)
	$(MAKE) victoria_2.build
	$(MAKE) victoria_2.test


bt_perf:
	$(MAKE) $(OUTDIR)/bt_perf

awallin.build_victoria_targets:
	$(MAKE) WRLVER=wrl18 MACHINE=axxiaarm64-prime.32 clean all awallin.catch_info
	$(RM) -r out/axxiaarm64-prime.32.thumb
	$(MV) out/axxiaarm64-prime.32 out/axxiaarm64-prime.32.thumb
	$(MAKE) WRLVER=wrl18 MACHINE=axxiaarm64-prime.32 BT_PERFTEST=1 clean all awallin.catch_info
	$(RM) -r out/axxiaarm64-prime.32.arm
	$(MV) out/axxiaarm64-prime.32 out/axxiaarm64-prime.32.arm

awallin.build_amarillo_targets:
	$(MAKE) WRLVER=wrl18 MACHINE=axxiaarm-prime clean all awallin.catch_info
	$(RM) -r out/axxiaarm-prime.thumb
	$(MV) out/axxiaarm-prime out/axxiaarm-prime.thumb
	$(MAKE) WRLVER=wrl18 MACHINE=axxiaarm-prime BT_PERFTEST=1 clean all awallin.catch_info
	$(RM) -r out/axxiaarm-prime.arm
	$(MV) out/axxiaarm-prime out/axxiaarm-prime.arm

awallin.catch_info:
	$(TRACE)
	$(SDK); $$NM $(OUTDIR)/bt_perf > $(OUTDIR)/bt_perf.nm
	$(SDK); $$OBJDUMP -x $(OUTDIR)/bt_perf > $(OUTDIR)/bt_perf.objdump.x
	$(SDK); $$OBJDUMP -d --syms --special-syms $(OUTDIR)/bt_perf > $(OUTDIR)/bt_perf.objdump.d
	$(SDK); $$OBJDUMP --syms --special-syms $(OUTDIR)/bt_perf > $(OUTDIR)/bt_perf.objdump.ss
	$(SDK); $${CROSS_COMPILE}readelf -p .GCC.command.line $(OUTDIR)/bt_perf > $(OUTDIR)/bt_perf.readelf
	$(Q)file $(OUTDIR)/bt_perf > $(OUTDIR)/bt_perf.file
	$(Q)ls -al $(OUTDIR)/bt_perf > $(OUTDIR)/bt_perf.ll
	$(Q)size $(OUTDIR)/bt_perf > $(OUTDIR)/bt_perf.size

awallin.help:
	$(call run-help, userconfig-awallin.mk)

help:: awallin.help
