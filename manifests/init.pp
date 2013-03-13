class postfix($smtp_host, $root_email_address, $inet_interfaces='loopback-only') {

  $postfix_pkgs = ['postfix', 'bsd-mailx']

  package { $postfix_pkgs :
    ensure  => installed,
  }

  service { 'postfix':
    ensure => running,
    require => Package[$postfix_pkgs],
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
    require => Package[$postfix_pkgs],
  }

  file { '/etc/aliases':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('postfix/aliases.erb'),
    notify  => [Service['postfix'], Exec['newaliases']],
    require => Package[$postfix_pkgs],
  }

  exec { 'newaliases':
    command     => '/usr/bin/newaliases',
    refreshonly => true,
  }

  # legcay way
  file {'/root/.forward':
    ensure  => absent,
  }
}
