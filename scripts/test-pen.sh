#!/bin/bash

cd /root/.emacs.d/pen.el
git clean -fd .
git fetch -a
git reset --hard origin/master
git pull

cd /root/.emacs.d/prompts
git clean -fd .
git fetch -a
git reset --hard origin/master;
git pull

cd
./run.sh