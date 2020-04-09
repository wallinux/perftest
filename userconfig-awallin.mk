# awallin user config file
#

ama1 ama2 vic1 vic2:
	$(TRACE)
	$(MAKE) target.all TARGET_IP=$@
