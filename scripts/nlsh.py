#!/usr/bin/env python3.8
# -*- coding: utf-8 -*-

# This script is for running nlsh
# https://mullikine.github.io/posts/nlsh-natural-language-shell/

from shanepy import *
import shanepy

import sys
import yaml

sys.stdin = open("/dev/tty")  # not idempotent. only works for import code

if not len(sys.argv) > 1:
    exit(1)

os = sys.argv[1]

filename = "/home/shane/source/git/semiosis/prompts/prompts/nlsh-2.prompt"

with open(filename) as f:
    data = f.read()

postprocessor = yaml.load(data)["postprocessor"].strip()

ogprompt = yaml.load(data)["prompt"]
ogprompt = ogprompt.replace("<1>", os)
ogprompt = ogprompt.replace("<Operating System>", os)
ogprompt = ogprompt.replace("<delim>", "###")

# template doesn't need to end in a newline but template+answer must end in
# newline
template = yaml.load(data)["repeater"]

import os, click, openai, shlex


def b(c, inputstring="", timeout=0):
    """Runs a shell command
    This function always has stdin and stdout.
    Don't do anything fancy here with ttys, handling stdin and stdout.
    If I wan't to use tty programs, then use a ttyize/ttyify script.
    echo hi | ttyify vim | cat"""

    #  c = xc(c)

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


while True:
    request = input(click.style("nlsh> ", "red", bold=True))
    prompt = ogprompt.rstrip() + "\n" + template.format(request).rstrip()

    result = openai.Completion.create(
        #  engine='davinci', prompt=prompt.strip(), stop="\n\n", max_tokens=100, temperature=.0
        engine="davinci",
        prompt=prompt.strip(),
        stop="###",
        max_tokens=100,
        temperature=0.0,
    )

    command = result.choices[0]["text"].strip()
    command = b(postprocessor, command)[0]
    prompt = prompt.strip() + " " + command + "\n###\n"

    print(command)
