# awallin user config file
#

ama1 ama2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm-prime TARGET_IP=$@

vic1 vic2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm64-prime TARGET_IP=$@
