# awallin user config file
#

ama1 ama2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm-prime TARGET_IP=$@

vic1 vic2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm64-prime TARGET_IP=$@

QEMU_PORT 	?= 2222
qemuarm64:
	$(TRACE)
	$(MAKE) target.all MACHINE=$@ TARGET_IP=localhost SSH_PORT=$(QEMU_PORT)
	#$(MAKE) target64.all MACHINE=qemuarm64 TARGET_IP=localhost SSH_PORT=$(QEMU_PORT)

qemuarm:
	$(TRACE)
	$(MAKE) target.all MACHINE=$@ TARGET_IP=localhost SSH_PORT=$(QEMU_PORT)

dwarf.%:
	$(TRACE)
	$(MAKE) $* CALLGRAPH=dwarf

fp.%:
	$(TRACE)
	$(MAKE) $* CALLGRAPH=fp

