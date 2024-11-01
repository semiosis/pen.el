#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import tensorflow as tf

import shanepy
from shanepy import *

#tf.version
# tv(str(tf.version))
# <module 'tensorflow._api.v2.version' from '/usr/local/lib/python3.5/dist-packages/tensorflow/_api/v2/version/__init__.py'>

def fizzbuzz(max_num):
  counter = tf.constant(0)
  max_num = tf.convert_to_tensor(max_num)
  # print(type(max_num)) # <class 'tensorflow.python.framework.ops.EagerTensor'>

  for num in range(1, max_num.numpy()+1):
    num = tf.constant(num)
    if int(num % 3) == 0 and int(num % 5) == 0:
      print('FizzBuzz')
    elif int(num % 3) == 0:
      print('Fizz')
    elif int(num % 5) == 0:
      print('Buzz')
    else:
      print(num.numpy())
      counter += 1

fizzbuzz(10)