#!/usr/bin/env python3
##!/usr/bin/env python3-e2dn
# -*- coding: utf-8 -*-

import requests
import sys
import shanepy
from shanepy import *
from bs4 import BeautifulSoup
from gensim.summarization import summarize
import os.path

# 'https://www.npr.org/2019/07/10/740387601/university-of-texas-austin-promises-free-tuition-for-low-income-students-in-2020'

# vim +/"TextRank" "$NOTES/ws/nlp-natural-language-processing/glossary.txt"

url = sys.argv[1]

if not(os.path.exists(url) and os.path.isfile(url)):
    page = requests.get(url).text
    soup = BeautifulSoup(page)
    headline = soup.find('h1').get_text()
    print(headline + ".")
    p_tags = soup.find_all('p')
    p_tags_text = [tag.get_text().strip() for tag in p_tags]
    sentence_list = [sentence for sentence in p_tags_text if not '\n' in sentence]
    sentence_list = [sentence for sentence in sentence_list if '.' in sentence]
    article = ' '.join(sentence_list)
else:
    article = cat(url)

print(article)
exit(0)
summary = summarize(article, ratio=0.3)

print(summary)

# print(f'Length of original article: {len(article)}')
# print(f'Length of summary: {len(summary)} \n')
# print(f'Headline: {headline} \n')
# print(f'Article Summary:\n{summary}'),