#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import socket
import sys

def connect(port):
    conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    conn.connect(('127.0.0.1', port)) # ip and port running emacs
    return conn

if __name__ == '__main__':

    if not len(sys.argv) > 1:
        exit(1)

    conn = connect(int(sys.argv[1]))

    # TODO Make this into a readline-wrappable REPL

    # now you send your desired elisps commands like this:
    conn.send(sys.argv[2].encode())
    # conn.send(b'(next-line)')
    # conn.send(b'(insert "foo bar")')
