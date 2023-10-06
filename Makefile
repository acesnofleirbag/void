BIN = void
CC = gcc
CFLAGS = -Wall -Werror -Wextra -pedantic -std=c99
DEBUG = 0
KERNEL_SRC := $(wildcard src/*.c)
KERNEL_OBJ := $(patsubst %.c, %.o, $(KERNEL_SRC))
OUTDIR = build
VERSION = 0_0_0

ifeq ($(DEBUG),1)
	CFLAGS += -g -O0
endif

.PHONY: help
help:
	@echo
	@echo "targets:"
	@echo
	@echo "  build        build the void kernel"
	@echo "  lint         run the clang-format linter"
	@echo "  spark        generate bootloader obj file"
	@echo "  bootdisk     generate a bootable image (void_[version].img)"
	@echo

# == bootloader == 

BOOTLOADER_BASEPATH = contrib/spark
BOOTLOADER_SRC := $(wildcard $(BOOTLOADER_BASEPATH)/src/*.asm)
BOOTLOADER_OBJ := $(patsubst %.asm, %.o, $(BOOTLOADER_SRC))

%.o: %.asm
	nasm -f bin $< -o $(subst $(BOOTLOADER_BASEPATH)/src/, $(OUTDIR)/, $@)

.PHONY: spark
spark:
	nasm -f bin $(BOOTLOADER_BASEPATH)/src/spark.asm -o $(OUTDIR)/spark.o

.PHONY: bootdisk
bootdisk: $(BOOTLOADER_OBJ)
	dd if=/dev/zero of=$(OUTDIR)/void_$(VERSION).img bs=512 count=2880
	# put spark (bootloader) on the 1st sector
	dd conv=notrunc if=$(OUTDIR)/spark.o of=$(OUTDIR)/void_$(VERSION).img bs=512 count=1 seek=0
	# put void (kernel) on the 2nd sector
	dd conv=notrunc if=$(OUTDIR)/void.o of=$(OUTDIR)/void_$(VERSION).img bs=512 count=1 seek=1

# == kernel ==

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $(subst src/, $(OUTDIR)/, $@)

.PHONY: build
build: $(KERNEL_OBJ)
	$(CC) $(CFLAGS) -o $(OUTDIR)/$(BIN) $(subst src/, $(OUTDIR)/, $<)

OBJ = $(shell find src -type f -iname '*.h' -or -iname '*.c')

.PHONY: lint
lint: $(OBJ)
	@clang-format -style=file -i $(OBJ)
	@echo "reformatted successfully"

.PHONY: run
run:
	qemu-system-i386 -machine q35 -fda build/void_0_0_0.img -gdb tcp::26000 -S
