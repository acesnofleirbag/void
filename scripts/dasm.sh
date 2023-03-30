#!/bin/sh

# Disassemble a binary file
#
# Usage: ./dasm.sh [binname] > debug.asm

if [ -z "$1" ]; then
    echo "ERR: Missing binname\n"
    echo "  Usage: ./dasm.sh [binname] > debug.asm"
    exit 1
fi

objdump -M intel -D $1
