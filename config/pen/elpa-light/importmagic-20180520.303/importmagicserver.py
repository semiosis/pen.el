# -*- coding: utf-8 -*-
"""
importmagic.el server
---------------------

Copyright (c) 2017 Nicolás Salas V.
Licensed under GPL3. See the LICENSE file for details

"""
import sexpdata
import sys
import threading
from collections import deque

import importmagic
from epc.server import EPCServer

server = EPCServer(('localhost', 0))

# We'll follow a very passive approach. I'm not really familiar with
# neither EPC or cl-lib. So please, don't expect to see a lot of
# quality in this code

index = None


# Since the transformation from Emacs Lisp to Python causes strings to
# be lists of separate characters, we need a function that can provide
# a regular string, which is this one.
def _stringify(input_param):
    return ''.join(input_param)

# Take an input parameter which is a list of lists and convert it to a
# key: value dictionary, extracting the symbol value if necessary.
def _lists_to_dict(input_param):
    def _value(item):
        return item.value() if isinstance(item, sexpdata.Symbol) else item

    if len(input_param) != 2: # there should only be 2 lists (keys and values)
        return {}
    else:
        return dict(zip(map(_value, input_param[0]),  # keys
                        map(_value, input_param[1]))) # values


# Construct the symbol index specified by the paths given. As the
# names suggest, these paths correspond to sys path and user_path. We
# still have to figure out if sys.path and user_path default values
# are ok.
def _build_index(sys_path=sys.path, user_path=None):
    # since index is a global variable, need the global keyword. I did
    # not know this
    # http://stackoverflow.com/questions/423379/using-global-variables-in-a-function-other-than-the-one-that-created-them
    global index
    try:
        paths = []

        if user_path is not None:
            if isinstance(user_path, list):
                paths = paths + user_path
            else:
                paths.append(user_path)

        if isinstance(sys_path, list):
            paths = paths + sys_path
        else:
            paths.append(sys_path)

        index = importmagic.SymbolIndex()
        index.build_index(paths=paths)
    except:
        print('Failed to build index')
        sys.exit(-1)


# Launch a thread that builds the index.
def build_index(sys_path=sys.path, user_path=None):
    thread = threading.Thread(target=_build_index, args=(user_path, sys_path))
    thread.daemon = True
    thread.start()


# Returns a list of every unresolved symbol in source.
@server.register_function
def get_unresolved_symbols(*source):
    source = _stringify(source)

    scope = importmagic.Scope.from_source(source)
    unres, unref = scope.find_unresolved_and_unreferenced_symbols()

    return list(unres)


# Returns a list of candidates that can import the queried symbol. The
# returned list is ordered by score, meaning that the first element is
# more likely to be appropriate.
@server.register_function
def get_candidates_for_symbol(*symbol):
    symbol = _stringify(symbol)

    candidates = deque([])
    for score, module, variable in index.symbol_scores(symbol):
        if variable is None:
            fmt = 'import {}'.format(str(module))
        else:
            fmt = 'from {} import {}'.format(str(module), str(variable))

        candidates.append(fmt)

    return list(candidates)


# Takes a list where the firest element is the source file as a string
# (assuming the call is from elisp) and the second element is the
# chosen import statement.
@server.register_function
def get_import_statement(source, import_statement, style):
    style = _lists_to_dict(style)

    imports = importmagic.importer.Imports(index, source)

    if style:
        imports.set_style(**style)

    if import_statement.startswith('import '):
        module = import_statement[7:]
        imports.add_import(module)
    else:
        separator = import_statement.find(' import ')
        module = import_statement[5:separator]

        if separator >= 0:
            imports.add_import_from(import_statement[5:separator],
                                    import_statement[(separator + 8):])

    start, end, new_statement = imports.get_update()

    return [start, end, new_statement]


# Adds the specified path to symbol index.
@server.register_function
def add_path_to_index(*path):
    path = _stringify(path)

    global index
    if index is None:
        return "Index not ready. Hang on a second."

    index.build_index([path])
    return 0


build_index()
server.print_port()
server.serve_forever()
