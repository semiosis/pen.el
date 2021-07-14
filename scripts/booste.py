#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import booste

string = 'This is a test for'
api_key = "your api key"
model_key = "gpt-j model key via dashbaord"

model_parameters = {
   "string": string,
   "length": 30,
   "temperature": 0.9,
   "topP" : 0.9,
   "stopToken" : '.'
}

print(booste.run(api_key, model_key, model_parameters))