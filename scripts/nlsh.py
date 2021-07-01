#!/usr/bin/env mypython
# -*- coding: utf-8 -*-

import sys
import yaml

import shanepy as spy

sys.stdin = open("/dev/tty")  # not idempotent. only works for import code

if not len(sys.argv) > 1:
    exit(1)

os = sys.argv[1]

filename = "$PROMPTS/nlsh-arch-linux-bash.prompt"

with open(filename) as f:
    data = f.read()

postprocessor = yaml.load(data)["postprocessor"].strip()

ogprompt = yaml.load(data)["prompt"]
ogprompt = ogprompt.replace("<1>", os)

# template doesn't need to end in a newline but template+answer must end in
# newline
template = yaml.load(data)["repeater"]
# ogprompt = ogprompt.replace("<2>", "{}")

import os, click, openai, shlex

#  import shanepy as spy

while True:
    # For some reason, when used with comint, the prompt appears before the
    # output, when without comint, it appears.
    # That would be because of rlwrap.
    request = input(click.style("nlsh> ", "red", bold=True))
    prompt = ogprompt.rstrip() + "\n" + template.format(request).rstrip()

    #  print(prompt)
    #  exit(0)

    result = openai.Completion.create(
        #  engine='davinci', prompt=prompt.strip(), stop="\n\n", max_tokens=100, temperature=.0
        engine="davinci",
        prompt=prompt.strip(),
        stop="###",
        max_tokens=100,
        temperature=0.0,
    )

    command = result.choices[0]["text"].strip()
    command = spy.b(postprocessor, command)[0]
    prompt = prompt.strip() + " " + command + "\n###\n"

    #  command = "sps zrepl -E " + shlex.quote(command)
    # command = "sps zrepl " + command

    #  spy.tv(command)
    print(command)

    #  command = "sps -E " + shlex.quote("zrepl -E " + shlex.quote(command.strip()))
    #  command = "sps -E " + shlex.quote("zrepl -E " + shlex.quote(command.strip()))

    #  if click.confirm(f'>>> Run: {click.style(command, "blue")}', default=True):

    # I don't want to interpret the script inside a format
    # if click.confirm('>>> Run: ' + click.style(command, "blue"), default=True):
    #     os.system(command)
