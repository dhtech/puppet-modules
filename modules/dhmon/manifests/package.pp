# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#

# Helper for installing debs from Github
# TODO(bluecmd): Remove if we switch to using a debian repository

define dhmon::package {
  $release = '1.2rc1'
  $debs = {
    'dhmon-common' =>   'dhmon-common_0.1-1ubuntu1.1.gbp3c2e3a_amd64.deb',
    'pinger' =>               'pinger_0.1-1ubuntu1.1.gbp3c2e3a_amd64.deb',
    'snmpcollector' => 'snmpcollector_0.1-1ubuntu1.1.gbp3c2e3a_amd64.deb'
  }

  $deb = $debs[$name]

  exec { "fetch-${name}":
    command =>
      "/usr/bin/wget https://github.com/dhtech/dhmon/releases/download/${release}/${deb} -O /var/cache/apt/archives/${deb}",
    creates => "/var/cache/apt/archives/${deb}",
  }
  package { $name:
    ensure   => installed,
    provider => dpkg,
    source   => "/var/cache/apt/archives/${deb}",
    require  => Exec["fetch-${name}"],
  }
}
