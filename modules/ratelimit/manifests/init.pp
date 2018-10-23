# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: ratelimit
#
# Allow connections from anywhere, but ratelimit new connections
#
# === Parameters
#
# [*ports*]
#   Ports to allow but ratelimit. Format (proto, port)
#
# [*hitcount*]
#   Hit count to allow (default 10).
#
# [*seconds*]
#   How many seconds to keep the blacklist.
#

class ratelimit ($ports, $hitcount = 5, $seconds = 60) {

  each($ports) |$entry| {
    $proto = $entry[0]
    $port = $entry[1]
    firewall {
      "600 v4 drop excessive $proto $port":
        recent    => 'update',
        rseconds  => $seconds,
        rhitcount => $hitcount,
        rname     => "ratelimit-v4-$proto-$port",
        rsource   => true,
        proto     => $proto,
        dport     => $port,
        action    => 'drop';
      "601 v4 accept $proto $port":
        recent    => 'set',
        rname     => "ratelimit-v4-$proto-$port",
        rsource   => true,
        proto     => $proto,
        dport     => $port,
        action    => 'accept';
      "600 v6 drop excessive $proto $port":
        recent    => 'update',
        rseconds  => $seconds,
        rhitcount => $hitcount,
        rname     => "ratelimit-v6-$proto-$port",
        rsource   => true,
        proto     => $proto,
        dport     => $port,
        action    => 'drop',
        provider  => 'ip6tables';
      "601 v6 accept $proto $port":
        recent    => 'set',
        rname     => "ratelimit-v6-$proto-$port",
        rsource   => true,
        proto     => $proto,
        dport     => $port,
        action    => 'accept',
        provider  => 'ip6tables';
    }
  }

}
