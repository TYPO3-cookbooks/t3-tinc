=begin
#<
Installs tinc
#>
=end
require 'openssl'

network = "t3o"

package "tinc"

# we want to override the options passed to `tincd` and include the --logfile option
template "/etc/default/tinc" do
  source "tinc.default.erb"
  mode 0655
  notifies :restart, "service[tinc]"
end

directory "/etc/tinc/#{network}"
directory "/etc/tinc/#{network}/hosts"

%w{up down}.each do |action|
  template "/etc/tinc/#{network}/tinc-#{action}" do
    source "tinc-#{action}.erb"
    mode "0755"
    notifies :reload, "service[tinc]"
  end
end

openssl_rsa_key "/etc/tinc/#{network}/rsa_key.priv" do
  key_length 4096
  notifies :run, "ruby_block[save-pubkey]"
  notifies :reload, "service[tinc]"
end

# as the openssl cookbook does not offer a way to write a public key file,
# we have to derive it from the private key, write it to file as well as
# save it as a node attribute so that our peers can read it.
ruby_block "save-pubkey" do
  block do
    pubkey_content = OpenSSL::PKey::RSA.new(File.read("/etc/tinc/#{network}/rsa_key.priv")).public_key
    File.write("/etc/tinc/#{network}/rsa_key.pub", pubkey_content)
    node.set['t3-tinc']['pub_key'] = pubkey_content
  end
  action :nothing
end

hosts_ConnectTo = []
# Search for all nodes that have node[t3-tinc][pub_key]
peers = search(:node, "t3-tinc_pub_key:*")
Chef::Log.info peers.to_s

peers.each do |peer|
  template "/etc/tinc/#{network}/hosts/#{peer['hostname']}" do
    source "host.erb"
    variables(
      :address => peer['fqdn'],
      :pub_key => peer['t3-tinc']['pub_key']
    )
    notifies :reload, "service[tinc]"
  end

  hosts_ConnectTo << peer['hostname'] unless peer['fqdn'] == node['fqdn']
end

template "/etc/tinc/#{network}/tinc.conf" do
  source "tinc.conf.erb"
  variables(
    :name => node['hostname'],
    :hosts_ConnectTo => hosts_ConnectTo
  )
  notifies :reload, "service[tinc]"
end

file "/etc/tinc/nets.boot" do
  content network + "\n"
end

service "tinc" do
  action [ :enable, :start ]
end
