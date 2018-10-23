# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import collections
import grp
import lib
import re
# Needed to read host's public SSH key for signing
import pypuppetdb


def login_path(host):
  if lib.get_domain(host) == 'EVENT':
    return '%s-services/login:%s' % (lib.get_current_event(), host)
  return 'services/login:%s' % (host, )


def sign_host_key(host):
  db = pypuppetdb.connect()
  hosts = {x.node: x for x in db.facts('ssh')}
  if host not in hosts:
    return ''
  ssh_keys = hosts[host].value
  # TODO(bluecmd): Only ecdsa for now
  ssh_key = ssh_keys['ecdsa']['key']
  # See if this key is already signed and saved
  login_data = lib.read_secret(login_path(host)) or {}
  if (login_data.get('sshecdsakey', None) == ssh_key and
          'sshecdsakey_signed' in login_data):
    return login_data['sshecdsakey_signed']
  res = lib.save_secret(
          'ssh/sign/server', cert_type='host', public_key=ssh_key)
  # Save key
  login_data['sshecdsakey'] = ssh_key
  login_data['sshecdsakey_signed'] = res['signed_key']
  lib.save_secret(login_path(host), **login_data)
  return res['signed_key']


def generate(host, *args):
  """Generate ldaplogin information.

  Args:
    *args: list(str): list of groups allowed to log in in addition to the
        default users.
    special keywords:
      - git: restrict non-sudo users to git-shell
      - otp: allow use of otp
      - [0-9]+: listen on given port
  """
  my_domain = lib.get_domain(host)
  ldap_servers = lib.get_nodes_with_package('ldap', my_domain)
  ldap_replicas = sorted(
          k for k, v in ldap_servers.iteritems() if 'master' not in v)

  # We want to be able to mutate the list
  args = list(args)

  if not ldap_replicas:
    # If we don't have any LDAP servers, don't include this module
    return {}

  # We're only using the lowest two parts of the FQDN for identity.
  # LDAP doesn't allow period in group names, replace with slash.
  ident = '-'.join(host.split('.')[0:2])

  info = {}

  # 'otp' is a special keyword to enable otp authentication on the host
  if 'otp' in args:
    args.remove('otp')
    info['use_otp'] = True

  # find numbers in args, use it for ports
  # 22 used by default, 2022 used for jumpgates
  info['ssh_ports'] = set([22, 2022])
  for arg in args:
    if re.match('^[0-9]+$', arg):
      info['ssh_ports'].add(int(arg))
      args.remove(arg)
  info['ssh_ports'] = list(info['ssh_ports'])

  # For sudo users we have two groups:
  # For event: services-event
  # For colo: services-colo
  # (.. and the ident-sudo group)
  info['sudo'] = [ident + '-sudo-access']
  services_group = 'services-colo-team'
  if my_domain == 'EVENT':
    services_group = 'services-team'
  info['sudo'].append(services_group)

  for arg in args:
    if arg.startswith('sudo'):
      _ , group = arg.split(':', 2)
      info['sudo'].append(group)

  # 'git' is a special keyword to enable restricting users to git-shell
  if 'git' in args:
    args.remove('git')
    info['gitshell'] = ','.join(['!' + x for x in info['sudo']]) + ',*'

  # Who should be allowed to log in to this system?
  info['logon'] = [
      (ident + '-access', 'ALL EXCEPT LOCAL'),
  ]

  # Allow sudo users to logon everywhere
  for user in info['sudo']:
    info['logon'].append((user, 'ALL'))

  # Add all explicit users
  for user in args:
    # Allow local logins as well to allow scripts to auth users
    formatted = user.format(event=lib.get_current_event())
    info['logon'].append((formatted, 'ALL'))

  # LDAP settings
  info['ldap'] = {'servers': [], 'servers_ip': {}}

  for server in ldap_replicas:
    info['ldap']['servers'].append(server)
    (server_ipv4, server_ipv6), = lib.resolve_nodes_to_ip([server]).values()
    info['ldap']['servers_ip'][server] = (server_ipv4, server_ipv6)

  info['ldap']['base'] = 'dc=tech,dc=dreamhack,dc=se'
  info['ldap']['mount'] = '/ldap'
  info['ca'] = lib.read_secret('ssh/config/ca')['public_key']
  info['host_cert'] = sign_host_key(host)
  info['panic_users'] = sorted(grp.getgrnam(services_group).gr_mem)

  return {'ldaplogin': info}
