#!/usr/bin/env python3

from pwn import *
import sys

{bindings}

context.binary = {bin_name}
context.terminal = ["tmux", "splitw", "-h"]


def conn():
    if "d" in sys.argv[1:]:
        context.log_level = "debug"
    if len(sys.argv) > 1 and "l" == sys.argv[1]:
        r = process({proc_args})
    elif len(sys.argv) > 1 and "g" in sys.argv[1]:
        r = gdb.debug({proc_args}, "b main")
    else:
        r = remote("addr", 1337)

    return r


def main():
    r = conn()

    # good luck pwning :)

    r.interactive()


if __name__ == "__main__":
    main()
