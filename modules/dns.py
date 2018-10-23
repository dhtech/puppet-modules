# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
def requires(host, *args):
  if not args:
    return []

  if 'slave' in args:
    role = 'slave'
  else:
    role = 'resolver'

  return ['bind(role=%s)' % role]
