class splunk{
  # Needed for 'ssl-cert' group
  ensure_packages(['ssl-cert'])
  
    file { '/etc/ssl/certs/splunk.event.dreamhack.se.crt':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0644',
    source => 'puppet:///letsencrypt/fullchain.pem',
    links  => 'follow',
  }

  file { '/etc/ssl/private/splunk.event.dreamhack.se.key':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0640',
    source => 'puppet:///letsencrypt/privkey.pem',
    links  => 'follow',
  }
}
