# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):
  info = {}

  local_targets = []

  if 'prom' in args:
    info['dhmoncolo::prometheus'] = {}
    }
  if 'prom-colo' in args:
    info['dhmoncolo::prometheus-colo'] = {}
    }
  if 'prom-event' in args:
    info['dhmoncolo::prometheus-event'] = {}
    }
  if 'alertmanager' in args:
    info['dhmoncolo:alertmanager'] ={}

  return info
