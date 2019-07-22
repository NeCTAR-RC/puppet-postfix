if FileTest.exists?("/usr/sbin/postconf")
  Facter.add('postfix_version') do
    setcode do
      %x{postconf -d | awk '/^mail_version/ {print $NF}'}.chomp
    end
  end
end
