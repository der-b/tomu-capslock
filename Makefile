TARGET_CPU=cortex-m0plus
LIBOPENCM3=./extern/libopencm3
LIBOPENCM3_LIB=$(LIBOPENCM3)/lib
LIBOPENCM3_INCLUDE=$(LIBOPENCM3)/include

# Copied from: https://github.com/im-tomu/tomu-quickstart/
# We keep this, since we don't want to overwrite the bootloader.
LDSCRIPT = ./tomu-efm32hg309.ld

CC = arm-none-eabi-gcc
MAKE = make
OBJCOPY = arm-none-eabi-objcopy

CFLAGS = -Wall -Wextra -std=gnu11 -Os

# tell libopencm3 which microcontroller we are using
CFLAGS += -DEFM32HG

# add inclde path for libopencm3 headers
CFLAGS += -I$(LIBOPENCM3_INCLUDE)

# specify the cpu architecture
CFLAGS += -mcpu=$(TARGET_CPU)

# instruction set option '-marm' (old) or '-mthumb' (new)
CFLAGS += -mthumb

# there is no hardware for floating pint instructions. Use software implementation.
CFLAGS += -mfloat-abi=soft

# these two options are for size opimization of the executables (Copied it from the Tomu-Quickstart repository: https://github.com/im-tomu/tomu-quickstart/)
CFLAGS += -ffunction-sections -fdata-sections  

# defining how global defined variables will be handled. no
CFLAGS += -fno-common

# optimisation wich saves up to three instructions per function call
CFLAGS += -fomit-frame-pointer

LDFLAGS = 

# add seracpath for linker scripts and libraries
LDFLAGS += -L$(LIBOPENCM3_LIB)

# link against opencm3 lib
LDFLAGS += -lopencm3_efm32hg

# do not link system startup files (we don't use linux on the microcontroller)
LDFLAGS += -nostartfiles

# removes unused magic code/data (size optimization of executable)
LDFLAGS += -Wl,--gc-sections

# mismatch is a common error while cross compiling
LDFLAGS += -Wl,--no-warn-mismatch

# omit build id (probably for size)
LDFLAGS += -Wl,--script=$(LDSCRIPT)

# omit build id (probably for size)
LDFLAGS += -Wl,--build-id=none




all: main.bin main.elf main.dfu

download: main.dfu
	dfu-util -D $<

clean:
	rm -f main.o main.elf main.bin main.dfu
	$(MAKE) -C $(LIBOPENCM3) clean

extern/libopencm3/include/libopencm3/efm32/hg/nvic.h:
	$(MAKE) -C $(LIBOPENCM3)

main.elf: main.o
	$(CC) $< $(CFLAGS) $(LDFLAGS) -o $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@


%.dfu: %.bin
	cp $< $@
	dfu-suffix -v 1209 -p 70b1 -a $@

%.o: %.c libopencm3
	$(CC) -c $< $(CFLAGS) -o $@ -MMD

include $(wildcard *.d)
