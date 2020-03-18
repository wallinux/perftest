# wrl18.mk

DISTRO_VERSION			= 10.18.44
MACHINES			+= axxiaarm-prime axxiaarm64-prime axxiaarm64-prime.32

CFLAGS_axxiaarm-prime		= -funwind-tables
CFLAGS_axxiaarm-prime		+= -fno-omit-frame-pointer

CFLAGS_axxiaarm64-prime		= -funwind-tables
CFLAGS_axxiaarm64-prime		+= -fno-omit-frame-pointer

CFLAGS_axxiaarm64-prime.32	= -funwind-tables
CFLAGS_axxiaarm64-prime.32	+= -fno-omit-frame-pointer
CFLAGS_axxiaarm64-prime.32	+= -mapcs-frame

TARGET_axxiaarm-prime		= amarillo_1
TARGET_axxiaarm64-prime		= victoria_2
TARGET_axxiaarm64-prime.32	= victoria_2

SDK_ENV_axxiaarm-prime		?= $(SDK_BASE)/environment-setup-cortexa15t2-neon-wrs-linux-gnueabi
SDK_ENV_axxiaarm64-prime	?= $(SDK_BASE)/environment-setup-aarch64-wrs-linux
SDK_ENV_axxiaarm64-prime.32	?= $(SDK_BASE)/environment-setup-armv7at2-neon-wrsmllib32-linux-gnueabi
