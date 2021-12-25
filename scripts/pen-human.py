#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import subprocess

from pathlib import Path

HUMAN_API_KEY = os.environ.get("HUMAN_API_KEY")
PEN_MODEL = os.environ.get("PEN_MODEL") or "DummyModel"
PEN_PROMPT = os.environ.get("PEN_PROMPT")
PEN_PAYLOADS = os.environ.get("PEN_PAYLOADS")
PEN_PRESENCE_PENALTY = os.environ.get("PEN_PRESENCE_PENALTY") or "0"
PEN_STOP_SEQUENCES = json.loads(os.environ.get("PEN_STOP_SEQUENCES") or "[\"\\n\"]") or ["\n"]
PEN_STOP_SEQUENCE = os.environ.get("PEN_STOP_SEQUENCE") or "\n"
# LOGPROBS can be None, and it doesn't return tonnes of logits.
PEN_LOGPROBS = os.environ.get("PEN_LOGPROBS") # or "10"
PEN_N_COMPLETIONS = os.environ.get("PEN_N_COMPLETIONS") or "2"
PEN_FREQUENCY_PENALTY = os.environ.get("PEN_FREQUENCY_PENALTY") or "0"
PEN_MAX_TOKENS = os.environ.get("PEN_MAX_TOKENS") or "30"
PEN_TEMPERATURE = os.environ.get("PEN_TEMPERATURE") or "0.1"
PEN_TOP_K = os.environ.get("PEN_TOP_K") or "0"
PEN_TOP_P = os.environ.get("PEN_TOP_P") or "0.0"

if PEN_LOGPROBS == "":
    PEN_LOGPROBS = None

if PEN_PAYLOADS:
    PEN_PAYLOADS = json.loads(PEN_PAYLOADS)

PEN_API_ENDPOINT = os.environ.get("PEN_API_ENDPOINT") or "https://localhost"
PEN_MODE = os.environ.get("PEN_MODE")
PEN_TRAILING_WHITESPACE = os.environ.get("PEN_TRAILING_WHITESPACE")


def xv(s):
    return os.path.expandvars(s)


def b(c, inputstring="", timeout=0):
    """Runs a shell command
    This function always has stdin and stdout.
    Don't do anything fancy here with ttys, handling stdin and stdout.
    If I wan't to use tty programs, then use a ttyize/ttyify script.
    echo hi | ttyify vim | cat"""

    c = xv(c)

    p = subprocess.Popen(
        c,
        shell=True,
        executable="/bin/sh",
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        close_fds=True,
    )
    p.stdin.write(str(inputstring).encode("utf-8"))
    p.stdin.close()
    output = p.stdout.read().decode("utf-8")
    p.wait()
    return [str(output), p.returncode]

result=b("pen-tvipe \"pen-pipify nano\"")[0]

# result = json.dumps(["PEN_MODEL: " + PEN_MODEL,
#                      "prompt: " + PEN_PROMPT,
#                      "n: " + str(PEN_N_COMPLETIONS),
#                      "top_k: " + str(PEN_TOP_K),
#                      "top_p: " + str(PEN_TOP_P),
#                      "log_probs: " + str(PEN_LOGPROBS),
#                      "stop_sequences: " + str(PEN_STOP_SEQUENCES),
#                      "maximum_tokens: " + str(PEN_MAX_TOKENS),
#                      "temperature: " + str(PEN_TEMPERATURE),
#                      "presence_penalty: " + str(PEN_PRESENCE_PENALTY),
#                      "frequency_penalty: " + str(PEN_FREQUENCY_PENALTY)])

cs = [result + PEN_STOP_SEQUENCE]

# It's just not working with 1 alone
if len(cs) == 1:
    print(PEN_PROMPT, end = '')
    print(cs[0])
else:
    for x in range(len(cs)):
        print(f"===== Completion %i =====" % x)
        print(PEN_PROMPT, end = '')
        print(cs[x])