# awallin user config file
#

ama1 ama2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm TARGET_IP=$@

vic1 vic2:
	$(TRACE)
	$(MAKE) target.all MACHINE=axxiaarm64 TARGET_IP=$@
