# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: resolvconf
#
# Rewrite /etc/resolv.conf.
#
# === Parameters
#
# [domain]
#   string of which domain this server belongs to
#
# [search]
#   list of domains. order which the host should search domains in.
#
# [nameservers]
#   list of resolvers. order in which to use a certain resolver.
#

class resolvconf ($domain, $search, $nameservers) {

  file { 'resolv.conf':
    ensure  => file,
    path    => '/etc/resolv.conf',
    content => template('resolvconf/resolv.conf.erb'),
  }

}
