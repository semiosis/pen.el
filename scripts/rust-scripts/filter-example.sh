#!/bin/bash
export TTY

cat filter-example.sh | rust-script --loop \
    "let mut n=0; move |l| {n+=1; println!(\"{:>6}: {}\",n,l.trim_end())}"
