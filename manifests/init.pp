class postfix {

  package {'postfix':
    ensure => installed,
  }

  service {'postfix':
    ensure => running,
    require => Package['postfix'],
  }

  file {'/etc/postfix/main.cf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('postfix/main.cf.erb'),
    notify  => Service['postfix'],
    require => Package['postfix'],
  }

  
}
