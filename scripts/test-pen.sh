#!/bin/bash

cd /root/.emacs.d/pen.el
git clean -fd .
git fetch -a
git reset --hard origin/master

cd ../prompts
git clean -fd .
git fetch -a
git reset --hard origin/master;

cd
./run