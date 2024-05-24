class postfix(
  $smtp_host,
  $root_email_address,
  $inet_interfaces='loopback-only',
  $aliases=[],
  $default_destination_concurrency_limit = 1,
  $default_destination_recipient_limit = 3,
  $myorigin = '$myhostname',
  $smtpd_tls_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $smtpd_tls_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $smtpd_use_tls = 'yes',
  $extra_config_options = {},
) {

  $postfix_pkgs = $facts['os']['family'] ? {
    'Debian'  => ['postfix', 'bsd-mailx'],
    'RedHat'  => ['postfix',],
    default   => ['postfix',],
  }

  package { $postfix_pkgs :
    ensure  => installed,
  }

  service { 'postfix':
    ensure  => running,
    require => Package[$postfix_pkgs],
  }

  file { '/etc/mailname':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => $facts['networking']['fqdn'],
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

}
