# wrl8.mk

DISTRO_VERSION			= 8.0.0.30
MACHINES			+= axxiaarm axxiaarm64-ml

CFLAGS_axxiaarm			= -funwind-tables
CFLAGS_axxiaarm			+= -fno-omit-frame-pointer

CFLAGS_axxiaarm64-ml		= -funwind-tables
CFLAGS_axxiaarm64-ml		+= -fno-omit-frame-pointer

TARGET_axxiaarm			= amarillo_1
TARGET_axxiaarm64-ml		= victoria_2

SDK_ENV_axxiaarm		?= $(SDK_BASE)/environment-setup-cortexa15-vfp-neon-wrs-linux-gnueabi
SDK_ENV_axxiaarm64-ml		?= $(SDK_BASE)/environment-setup-aarch64-wrs-linux

