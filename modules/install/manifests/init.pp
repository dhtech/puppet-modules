# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: install
#
# Class to make it easy to add software to services without writing
# complex puppet modules.
#
# === Parameters
#
# [*install*]
#   List of packages to install.
#
# [*purge*]
#   List of packages to purge.
#

class install ($install = [], $purge = []) {

  each($install) |$pkg| {
    package { "$pkg":
      ensure => installed,
    }
  }

  each($purge) |$pkg| {
    package { "$pkg":
      ensure => purged,
    }
  }
}
