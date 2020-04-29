# awallin user config file
#
.PHONY::ama1 ama2 vic1 vic2 qemuarm qemuarm64

ama1 ama2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm-prime TARGET_IP=$@
	$(MAKE) target.get MACHINE=axxiaarm64-prime TARGET_IP=$@

vic1 vic2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm64-prime TARGET_IP=$@
	$(MAKE) target.get MACHINE=axxiaarm64-prime TARGET_IP=$@

qemuarm:
	$(TRACE)
	$(MAKE) target.all MACHINE=$@ TARGET_IP=localhost

qemuarm64:
	$(TRACE)
	$(MAKE) target.all MACHINE=$@ TARGET_IP=localhost
	#$(MAKE) target64.all MACHINE=qemuarm64 TARGET_IP=localhost

dwarf.%:
	$(TRACE)
	$(MAKE) $* CALLGRAPH=dwarf

fp.%:
	$(TRACE)
	$(MAKE) $* CALLGRAPH=fp
