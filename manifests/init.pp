class postfix($smtp_host, $inet_interfaces='loopback-only') {

  package { ['postfix', 'bsd-mailx']:
    ensure => installed,
  }

  service { 'postfix':
    ensure => running,
    require => Package['postfix'],
  }

  file { '/etc/mailname':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => $::fqdn,
  }

  file { '/etc/postfix/main.cf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('postfix/main.cf.erb'),
    notify  => Service['postfix'],
    require => Package['postfix'],
  }

}
