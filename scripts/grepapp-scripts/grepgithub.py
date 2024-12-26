#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# https://grep.app/search?q=.%2A&regexp=true&filter[lang.pattern][0]=sql&filter[lang][0]=SQL
# ggh -q "select .* from .*" -r -flang SQL

# https://github.com/popovicn/grepgithub

# MIT License
# 
# Copyright (c) 2021 Nenad Popovic
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import argparse
import json
import os
import re
import time
import uuid

import bs4
import requests
import sys

from requests_toolbelt.utils import dump

C_BANNER = "\033[35;1m"
C_REPO = "\033[37;1m"
C_LINE_NUM = "\033[31m"
C_LINE = "\033[37;2m"
C_MARK = "\033[32m"
C_RST = "\033[0m"

# BANNER = """
#    {bc}____ ____ ____ ___  {r}____ _ ___ _  _ _  _ ___ {r} 
#    {bc}| __ |__/ |___ |__] {r}| __ |  |  |__| |  | |__] {r}
#    {bc}|__| |  \\ |___ |   {r} |__| |  |  |  | |__| |__] {r}

# """.format(bc=C_BANNER, r=C_RST)

BANNER = "Grep Github"

class OutStream:
    def __init__(self, output_file=None):
        self.output_file = open(output_file, 'w') if output_file else None

    def write(self, content, *args):
        if args:
            print(content.format(*args))
            if self.output_file:
                self.output_file.write(content.format(*args) + "\n")
        else:
            print(content)
            if self.output_file:
                self.output_file.write(content + "\n")

    def close(self):
        if self.output_file:
            self.output_file.close()


class Hits:

    def __init__(self):
        self.mark_start_placeholder = str(uuid.uuid4())
        self.mark_end_placeholder = str(uuid.uuid4())
        self.hits = {}

    def _parse_snippet(self, snippet):
        matches = {}
        soup = bs4.BeautifulSoup(snippet, 'lxml')
        for tr in soup.select('tr'):
            line_num = tr.select("div.lineno")[0].text.strip()
            line = tr.select("pre")[0].decode_contents()
            if "<mark" not in line:
                continue
            else:
                line = re.sub(r'<mark[^<]*>',  self.mark_start_placeholder, line)
                line = line.replace("</mark>", self.mark_end_placeholder)
                line = bs4.BeautifulSoup(line, 'lxml').text
                line = line.replace(self.mark_start_placeholder, C_RST+C_MARK)
                line = line.replace(self.mark_end_placeholder, C_RST + C_LINE)
                matches[line_num] = line
        return matches

    def add_hit(self, repo, path, snippet):
        if repo not in self.hits:
            self.hits[repo] = {}
        if path not in self.hits[repo]:
            self.hits[repo][path] = {}
        # Parse snippet
        for line_num, line in self._parse_snippet(snippet).items():
            self.hits[repo][path][line_num] = line

    def merge(self, hits2):
        for hit_repo, path_data in hits2.hits.items():
            if hit_repo not in self.hits:
                self.hits[hit_repo] = {}
            for path, lines in path_data.items():
                if path not in self.hits[hit_repo]:
                    self.hits[hit_repo][path] = {}
                for line_num, line in lines.items():
                    self.hits[hit_repo][path][line_num] = line


def fail(error_msg):
    print("Error: {}\033[0m".format(error_msg))
    exit(1)


def fetch_grep_app(page, args):

    params = {
        'q': args.query,
        'page': page
    }
    url = "https://grep.app/api/search"

    if args.use_regex:
        params['regexp'] = 'true'
    elif args.whole_words:
        params['words'] = 'true'

    if args.case_sensitive:
        params['case'] = 'true'
    if args.repo_filter:
        params['f.repo.pattern'] = args.repo_filter
    if args.path_filter:
        params['f.path.pattern'] = args.path_filter
    if args.lang_filter:
        params['f.lang'] = args.lang_filter.split(',')
    response = requests.get(url, params=params)

    print(dump.dump_all(response).decode("utf-8"), file=sys.stderr)


    if response.status_code != 200:
        fail("HTTP {} {}".format(response.status_code, url))
    data = response.json()
    count = data['facets']['count']
    hits = Hits()
    for hit_data in data['hits']['hits']:
        repo = hit_data['repo']['raw']
        path = hit_data['path']['raw']
        snippet = hit_data['content']['snippet']
        hits.add_hit(repo, path, snippet)

    if count > 10 * page:
        return page + 1, hits, count
    else:
        return None, hits, count


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('-q', dest='query', help='Query string, required', required=True)
    parser.add_argument('-c', dest='case_sensitive', action='store_true', help='Case sensitive search')
    parser.add_argument('-r', dest='use_regex', action='store_true', help='Use regex query. Cannot be used with -w')
    parser.add_argument('-w', dest='whole_words', action='store_true', help='Search whole words. Cannot be used with -r')
    parser.add_argument('-n', dest='n', help='N queries')
    parser.add_argument('-frepo', dest='repo_filter', help='Filter repository')
    parser.add_argument('-fpath', dest='path_filter', help='Filter path')
    parser.add_argument('-flang', dest='lang_filter', help='Filter language (eg. Python,C,Java). Use comma for multiple values')
    parser.add_argument('-json', dest='json_output', action='store_true', help='JSON output')
    parser.add_argument('-o', dest='output_file', help='Output file path')
    parser.add_argument('-m', dest='monochrome', action='store_true', help='Monochrome output')
    args = parser.parse_args()

    out_stream = OutStream(output_file=args.output_file)

    if args.monochrome:
        C_BANNER = ""
        C_REPO = ""
        C_LINE_NUM = ""
        C_LINE = ""
        C_MARK = ""
        C_RST = ""

    if not args.json_output:
        out_stream.write(BANNER)
        out_stream.write("> Fetching 10/?")
    next_page, hits, count = fetch_grep_app(page=1, args=args)
    i=0
    # print(args.n)
    # quit()
    while next_page and next_page < 101 and ( not args.n or i < int(args.n) ):    # Does not paginate after 100
        time.sleep(1)
        i+=1
        if not args.json_output:
            out_stream.write("> Fetching {}/{}", 10*next_page, count)
        next_page, page_hits, _ = fetch_grep_app(page=next_page, args=args)
        hits.merge(page_hits)

    if args.json_output:
        json_out = json.dumps(hits.hits, indent=4)
        out_stream.write(json_out)
    else:
        # Pretty cli
        try:
            cli_w = os.get_terminal_size().columns
        except OSError:
            cli_w = 40
        c_blue = "\033[34;1m"
        c_rst = "\033[0m"
        separator = "_" * cli_w
        repo_ct = 0
        file_ct = 0
        line_ct = 0
        for repo, path_data in hits.hits.items():
            repo_ct += 1
            out_stream.write(separator)
            out_stream.write("")
            out_stream.write("{}{}{}", C_REPO, repo, C_RST)
            for path, lines in path_data.items():
                file_ct += 1
                out_stream.write("    /{}", path)
                for line_num, line in lines.items():
                    line_ct += 1
                    num_fmt = str(line_num).rjust(4)
                    out_stream.write("      {}{}:{} {}{}{}", C_LINE_NUM, num_fmt, C_RST, C_LINE, line, C_RST)

        out_stream.write(separator)
        out_stream.write("")
        out_stream.write("> Repositories  {}{}{}", C_MARK, repo_ct, C_RST)
        out_stream.write("> Files         {}{}{}", C_MARK, file_ct, C_RST)
        out_stream.write("> Matched lines {}{}{}", C_MARK, line_ct, C_RST)

    out_stream.close()
