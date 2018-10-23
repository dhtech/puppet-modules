# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):
  networks = list(lib.get_networks_with_name('EVENT@DREAMHACK'))

  # We also allow lookups from RFC1918 nets
  rfc1918_nets = [
    '10.0.0.0/8',
    '172.16.0.0/12',
    '192.168.0.0/16',
  ]

  networks.extend(rfc1918_nets)

  role = filter(lambda x: x.startswith('role='), args)[0].split('=')[1]

  private_zones = [
    '10.in-addr.arpa',
    '16.172.in-addr.arpa',
    '0.30.172.in-addr.arpa',
    '2.29.172.in-addr.arpa',
    '168.192.in-addr.arpa',
    'event.dreamhack.local',
    'tech.dreamhack.local',
  ]

  zones = [
    'dhte.ch',
    'event.dreamhack.se',
    'net.dreamhack.se',
    'tech.dreamhack.se',
    '0.4.2.2.5.0.a.2.ip6.arpa',
    '7.3.3.1.0.0.b.4.2.0.a.2.ip6.arpa',
    '2.4.2.2.5.0.a.2.ip6.arpa',
    '128.80.77.in-addr.arpa',
    '129.80.77.in-addr.arpa',
    '130.80.77.in-addr.arpa',
    '131.80.77.in-addr.arpa',
    '132.80.77.in-addr.arpa',
    '133.80.77.in-addr.arpa',
    '134.80.77.in-addr.arpa',
    '135.80.77.in-addr.arpa',
    '136.80.77.in-addr.arpa',
    '137.80.77.in-addr.arpa',
    '138.80.77.in-addr.arpa',
    '139.80.77.in-addr.arpa',
    '140.80.77.in-addr.arpa',
    '141.80.77.in-addr.arpa',
    '142.80.77.in-addr.arpa',
    '143.80.77.in-addr.arpa',
    '144.80.77.in-addr.arpa',
    '145.80.77.in-addr.arpa',
    '146.80.77.in-addr.arpa',
    '147.80.77.in-addr.arpa',
    '148.80.77.in-addr.arpa',
    '149.80.77.in-addr.arpa',
    '150.80.77.in-addr.arpa',
    '151.80.77.in-addr.arpa',
    '152.80.77.in-addr.arpa',
    '153.80.77.in-addr.arpa',
    '154.80.77.in-addr.arpa',
    '155.80.77.in-addr.arpa',
    '156.80.77.in-addr.arpa',
    '157.80.77.in-addr.arpa',
    '158.80.77.in-addr.arpa',
    '159.80.77.in-addr.arpa',
    '160.80.77.in-addr.arpa',
    '161.80.77.in-addr.arpa',
    '162.80.77.in-addr.arpa',
    '163.80.77.in-addr.arpa',
    '164.80.77.in-addr.arpa',
    '165.80.77.in-addr.arpa',
    '166.80.77.in-addr.arpa',
    '167.80.77.in-addr.arpa',
    '168.80.77.in-addr.arpa',
    '169.80.77.in-addr.arpa',
    '170.80.77.in-addr.arpa',
    '171.80.77.in-addr.arpa',
    '172.80.77.in-addr.arpa',
    '173.80.77.in-addr.arpa',
    '174.80.77.in-addr.arpa',
    '175.80.77.in-addr.arpa',
    '176.80.77.in-addr.arpa',
    '177.80.77.in-addr.arpa',
    '178.80.77.in-addr.arpa',
    '179.80.77.in-addr.arpa',
    '180.80.77.in-addr.arpa',
    '181.80.77.in-addr.arpa',
    '182.80.77.in-addr.arpa',
    '183.80.77.in-addr.arpa',
    '184.80.77.in-addr.arpa',
    '185.80.77.in-addr.arpa',
    '186.80.77.in-addr.arpa',
    '187.80.77.in-addr.arpa',
    '188.80.77.in-addr.arpa',
    '189.80.77.in-addr.arpa',
    '190.80.77.in-addr.arpa',
    '191.80.77.in-addr.arpa',
    '192.80.77.in-addr.arpa',
    '193.80.77.in-addr.arpa',
    '194.80.77.in-addr.arpa',
    '195.80.77.in-addr.arpa',
    '196.80.77.in-addr.arpa',
    '197.80.77.in-addr.arpa',
    '198.80.77.in-addr.arpa',
    '199.80.77.in-addr.arpa',
    '200.80.77.in-addr.arpa',
    '201.80.77.in-addr.arpa',
    '202.80.77.in-addr.arpa',
    '203.80.77.in-addr.arpa',
    '204.80.77.in-addr.arpa',
    '205.80.77.in-addr.arpa',
    '206.80.77.in-addr.arpa',
    '207.80.77.in-addr.arpa',
    '208.80.77.in-addr.arpa',
    '209.80.77.in-addr.arpa',
    '210.80.77.in-addr.arpa',
    '211.80.77.in-addr.arpa',
    '212.80.77.in-addr.arpa',
    '213.80.77.in-addr.arpa',
    '214.80.77.in-addr.arpa',
    '215.80.77.in-addr.arpa',
    '216.80.77.in-addr.arpa',
    '217.80.77.in-addr.arpa',
    '218.80.77.in-addr.arpa',
    '219.80.77.in-addr.arpa',
    '220.80.77.in-addr.arpa',
    '221.80.77.in-addr.arpa',
    '222.80.77.in-addr.arpa',
    '223.80.77.in-addr.arpa',
    '224.80.77.in-addr.arpa',
    '225.80.77.in-addr.arpa',
    '226.80.77.in-addr.arpa',
    '227.80.77.in-addr.arpa',
    '228.80.77.in-addr.arpa',
    '229.80.77.in-addr.arpa',
    '230.80.77.in-addr.arpa',
    '231.80.77.in-addr.arpa',
    '232.80.77.in-addr.arpa',
    '233.80.77.in-addr.arpa',
    '234.80.77.in-addr.arpa',
    '235.80.77.in-addr.arpa',
    '236.80.77.in-addr.arpa',
    '237.80.77.in-addr.arpa',
    '238.80.77.in-addr.arpa',
    '239.80.77.in-addr.arpa',
    '240.80.77.in-addr.arpa',
    '241.80.77.in-addr.arpa',
    '242.80.77.in-addr.arpa',
    '243.80.77.in-addr.arpa',
    '244.80.77.in-addr.arpa',
    '245.80.77.in-addr.arpa',
    '246.80.77.in-addr.arpa',
    '247.80.77.in-addr.arpa',
    '248.80.77.in-addr.arpa',
    '249.80.77.in-addr.arpa',
    '250.80.77.in-addr.arpa',
    '251.80.77.in-addr.arpa',
    '254.80.77.in-addr.arpa',
    '255.80.77.in-addr.arpa',
  ]

  allow_transfer = [
    'localhost;',
    '77.80.255.5;   # ns1.net.dreamhack.se',
    '77.80.231.201; # ddns1@dh',
    '77.80.231.202; # ddns2@dh',
    '77.80.231.213; # ddns3@dh',
    '77.80.255.12;  # eest test obsd',
    '77.80.255.54;  # eest test debian',
  ]

  ddns_hosts = [
    '77.80.231.201;  # ddns1@dh',
    '77.80.231.202;  # ddns2@dh',
    '77.80.231.213;  # ddns3@dh',
  ]

  also_notify = []

  also_notify.extend(ddns_hosts)

  rfc_1918_resolvers = [
    '77.80.230.0/23; # tech-servers',
    '77.80.254.0/23; # tech-colo',
  ]

  info = {}
  info['role'] = role
  info['networks'] = networks
  info['zones'] = zones
  info['allow_transfer'] = allow_transfer
  info['private_zones'] = private_zones
  info['also_notify'] = also_notify
  info['rfc_1918_resolvers'] = rfc_1918_resolvers
  return {'bind': info}
