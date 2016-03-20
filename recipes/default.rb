=begin
#<
Installs tinc
#>
=end

network = "t3o"

package "tinc"

directory "/etc/tinc/#{network}"
directory "/etc/tinc/#{network}/hosts"

%w{up down}.each do |action|
  template "/etc/tinc/#{network}/tinc-#{action}" do
    source "tinc-#{action}.erb"
    mode "0755"
    notifies :restart, "service[tinc]"
  end
end

openssl_x509 "/etc/tinc/#{network}/rsa_key.pub" do
  common_name node['fqdn']
  org "TYPO3"
  org_unit ""
  country "DE"
  key_file "/etc/tinc/#{network}/rsa_key.priv"
  key_length 4096
end

ruby_block "save-pub-key" do
  block do
    node.set_unless['t3-tinc']['pub_key'] = File.read("/etc/tinc/#{network}/rsa_key.pub")
  end
end

hosts_ConnectTo = []
peers = search(:node, "t3-tinc:*")
Chef::Log.info peers.to_s

peers.each do |peer|
  next if peer['fqdn'] == node['fqdn']
  hosts_ConnectTo << peer['hostname']

  template "/etc/tinc/#{network}/hosts/#{peer['hostname']}" do
    source "host.erb"
    variables(
      :address => peer['fqdn'],
      :pub_key => peer['t3-tinc']['pub_key']
    )
    notifies :restart, "service[tinc]"
  end
end

template "/etc/tinc/#{network}/tinc.conf" do
  source "tinc.conf.erb"
  variables(
    :name => node['hostname'],
    :hosts_ConnectTo => hosts_ConnectTo
  )
  notifies :restart, "service[tinc]"
end

file "/etc/tinc/nets.boot" do
  content network + "\n"
end

service "tinc" do
  action [ :enable, :start ]
end
