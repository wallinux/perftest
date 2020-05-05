# awallin user config file
#
.PHONY::ama1 ama2 vic1 vic2 qemuarm qemuarm64 fp.* dwarf.*

ama1 ama2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm-prime TARGET=$@
	$(MAKE) target.get MACHINE=axxiaarm64-prime TARGET=$@

vic1 vic2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm64-prime TARGET=$@
	$(MAKE) target.get MACHINE=axxiaarm64-prime TARGET=$@

qemuarm:
	$(TRACE)
	$(MAKE) target.all MACHINE=$@ TARGET=localhost

qemuarm64:
	$(TRACE)
	$(MAKE) target.all MACHINE=$@ TARGET=localhost
ifdef ARM64
	$(MAKE) target64.all MACHINE=$@ TARGET=localhost
endif
	$(MAKE) target.get MACHINE=$@ TARGET=localhost

dwarf.%:
	$(TRACE)
	$(MAKE) $* CALLGRAPH=dwarf

fp.%:
	$(TRACE)
	$(MAKE) $* CALLGRAPH=fp

localscript.arm.%:
	$(TRACE)
	$(Q)RUN=run_host CALLGRAPH=$(CALLGRAPH) $(PERFTEST_ALL) arm $*
	$(Q)diff -u $*/root/perftest/out/profiling/arm/$(CALLGRAPH)/perf.out $*/root/perftest/out/profiling/arm/$(CALLGRAPH)/perf.native.out

localscript.arm64.%:
	$(TRACE)
	$(Q)RUN=run_host CALLGRAPH=$(CALLGRAPH) $(PERFTEST_ALL) arm64 $* 

localscript.thumb.%:
	$(TRACE)
	$(Q)RUN=run_host CALLGRAPH=$(CALLGRAPH) $(PERFTEST_ALL) thumb $* 
