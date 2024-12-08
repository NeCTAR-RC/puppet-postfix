class postfix (
  String $smtp_host,
  String $root_email_address,
  String $inet_interfaces                        = 'loopback-only',
  Array $aliases                                 = [],
  Integer $default_destination_concurrency_limit = 1,
  Integer $default_destination_recipient_limit   = 3,
  Array $mynetworks                              = [],
  String $myorigin                               = '$myhostname',
  String $smtpd_tls_cert_file                    = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  String $smtpd_tls_key_file                     = '/etc/ssl/private/ssl-cert-snakeoil.key',
  Enum['yes', 'no'] $smtpd_use_tls               = 'yes',
  Optional[String] $smtp_tls_security_level      = undef,
  String $smtp_tls_cafile                        = '/etc/ssl/certs/ca-certificates.crt',
  Hash $extra_config_options                     = {},
  Optional[String] $sasl_username                = undef,
  Optional[Sensitive[String]] $sasl_password     = undef,
) {

  $postfix_pkgs = $facts['os']['family'] ? {
    'Debian' => ['postfix', 'bsd-mailx'],
    'RedHat' => ['postfix',],
    default  => ['postfix',],
  }

  package { $postfix_pkgs :
    ensure => installed,
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

  # List of localhost networks to always be added
  $local_networks = ['127.0.0.0/8', '[::ffff:127.0.0.0]/104', '[::1]/128']
  $real_mynetworks = $local_networks + $mynetworks

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

  if ($sasl_password) {
    file { '/etc/postfix/sasl_passwd':
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => inline_epp('<%= $smtp_host %>	<%= $sasl_username %>:<%= $sasl_password %>'),
      notify  => Exec['rebuild-sasl-passwd'],
      require => Package[$postfix_pkgs],
    }

    exec { 'rebuild-sasl-passwd':
      command     => '/usr/sbin/postmap hash:/etc/postfix/sasl_passwd',
      cwd         => '/etc/postfix',
      refreshonly => true,
      notify      => Service['postfix'],
    }
  }

  # Firewall rules for any external networks given
  nectar::firewall::multisource {[ prefix($mynetworks, '300 smtp,') ]:
    jump  => 'ACCEPT',
    proto => 'tcp',
    dport =>  25,
  }
}
