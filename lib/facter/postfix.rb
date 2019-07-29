Facter.add('postfix_version') do
  setcode do
    postconf = Facter::Util::Resolution.exec('postconf -d')
    postconf.match(%r{^mail_version = (\d+\.\d+.*)$})[1] if postconf
  end
end
