#!/usr/bin/env rust-script
// cargo-deps: time="0.1.25"
// You can also leave off the version number, in which case, it's assumed
// to be "*".  Also, the `cargo-deps` comment *must* be a single-line
// comment, and it *must* be the first thing in the file, after the
// shebang.
// Multiple dependencies should be separated by commas:
// cargo-deps: time="0.1.25", libc="0.2.5"
fn main() {
    println!("{}", time::now().rfc822z());
}
