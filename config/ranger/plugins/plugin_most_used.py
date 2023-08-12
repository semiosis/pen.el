# To use this plugin you can type :set sort most-used
# To sort by default replace default set sort command in rc.conf with above mentioned

from __future__ import (absolute_import, division, print_function)
import os.path
import json
import threading
import time

import ranger.api
from ranger.api.commands import *
from ranger.container.directory import Directory

HOOK_INIT_OLD = ranger.api.hook_init


class State:
    def __init__(self):
        self.current_path = None
        self.is_looping = False
        self.weights_updated = False
        self.data = {
            'weights': {},
            'track': True,
            'save_interval': 0,
        }


dirname = os.path.dirname(__file__)
weights_path = os.path.join(dirname, 'plugin_most_used.json')
state = State()


def save():
    file = open(weights_path, 'w+')
    file.write(json.dumps(state.data))
    file.close()
    state.weights_updated = False


def save_loop():
    while state.is_looping:
        time.sleep(state.data['save_interval'])
        if state.weights_updated:
            save()


def sort(path):
    path = str(path)
    if path in state.data['weights']:
        return state.data['weights'][path] * (-1)
    else:
        return 1


def hook_init(fm):
    if os.path.exists(weights_path):
        file = open(weights_path, 'r')
        lines = file.read()
        file.close()
        try:
            state.data = json.loads(lines)
        except:
            fm.notify('plugin_most_used: json decode error')
            HOOK_INIT_OLD(fm)
            return
        if state.data['save_interval'] > 0:
            state.is_looping = True
            threading.Thread(target=save_loop).start()

    def update_weights(signal=None):

        if not state.data['track']:
            return
        if signal is not None:
            path = signal.new.path
        else:
            path = state.current_path
            state.current_path = None
        state.weights_updated = True

        if path in state.data['weights']:
            state.data['weights'][path] += 1
        else:
            state.data['weights'].update({path: 1})
        if state.data['save_interval'] == 0:
            save()

    def update_current_path(signal):
        state.current_path = signal.new.path

    fm.signal_bind('cd', lambda signal: update_weights(signal))
    fm.signal_bind('execute.before', lambda signal: update_weights())
    fm.signal_bind('move', update_current_path)
    fm.commands.commands['most_used_reorder'] = most_used_reorder
    fm.commands.commands['most_used_track'] = most_used_track
    HOOK_INIT_OLD(fm)


ranger.api.hook_init = hook_init
Directory.sort_dict['most-used'] = sort


class most_used_track(Command):
    def execute(self):
        if self.arg(1) == 'true':
            state.data['track'] = True
            save()
            self.fm.notify('Tracking is on.')
        elif self.arg(1) == 'false':
            state.data['track'] = False
            save()
            self.fm.notify('Tracking is off.')
        else:
            self.fm.notify('Invalid argument, valid ones are: true, false.')


class most_used_reorder(Command):
    def execute(self):
        self.fm.thisdir.files_all.sort(key=sort)
        self.fm.thisdir.refilter()


class most_used_optimize(Command):
    def execute(self):
        self.fm.notify('Optimizing..')
        count = 0
        for path in list(state.data['weights'].keys()):
            if not os.path.exists(path):
                del state.data['weights'][path]
                count += 1
        save()
        self.fm.notify('Removed ' + str(count) + ' entries.')


class most_used_save(Command):
    def execute(self):
        save()
        self.fm.notify('Saved.')


class most_used_save_interval(Command):
    def execute(self):
        # -1: save only with commands
        # 0: autosave when opening files or changing directories
        # > 0: updates after x seconds
        try:
            input = int(self.arg(1))
        except:
            self.fm.notify('Invalid argument, valid ones are: -1,0,1,2,3...')
            return

        if input < -1:
            self.fm.notify('Invalid argument, valid ones are: -1,0,1,2,3...')
            return
        state.data['save_interval'] = input
        save()
        if input > 0:
            state.is_looping = True
            threading.Thread(target=save_loop).start()
        else:
            state.is_looping = False
        self.fm.notify('Save interval updated.')





