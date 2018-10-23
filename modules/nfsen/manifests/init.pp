# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: nfsen
#
# Install nfsen
#

class nfsen {
    class {'nfsen::prereq': } ->
    class {'nfsen::install': }
}
