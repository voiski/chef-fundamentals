Chef Fundamentals
=================

This training is about the basics of the chef. Considering the bellow inputs:

- **ip**   `192.168.3.xx`
- **mask** `255.255.252.0`

> At any error check if exist some tip on the [Troubleshooting](#troubleshooting) at the end of the page

## Steps

### 1st Creating the project

- **node** :stew: vagrant init centos/7
- **node** :stew: vagrant up --provider virtualbox
- **node** :stew: [manual] Change Vagrantfile to use the given ip/mask and to be public

> config.vm.network "public_network", ip: "[ip]", netmask: "[mask]"

- **chef** :hocho: [manual] Create a account at [chef.io](https://manage.chef.io/login)
- **chef** :hocho: [manual] Download the skeleton project

### 2nd Registering the node on chef

- **node** :stew: vagrant destroy up
- **node** :stew: vagrant ssh
- **node** :stew: ip addr list
- **chef** :hocho: knife list
- **chef** :hocho: knife client list
- **chef** :hocho: new_ip=$(vagrant ssh -c "ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//'")
- **chef** :hocho: knife bootstrap $new_ip --sudo -x vagrant -P vagrant -N "node1"

### 3rd Creating and applying the first cookbook

- **node** :stew: [inside node as root] echo 'log_level :info' >> /etc/chef/client.rb
- **chef** :hocho: knife cookbook create apache
- **chef** :hocho: [manual] Edit *apache/recipes/default.rb*

```ruby
package 'httpd' { action :install }
service 'httpd' { action [ :enable, :start ] }
cookbook_file '/var/www/html/index.html' do
  source 'index.html'
  mode '0644'
end
```

- **chef** :hocho: [manual] Create *apache/files/default/index.html* with some html content
- **chef** :hocho: knife cookbook upload apache
- **chef** :hocho: knife node run_list add node1 "recipe[apache]"
- **node** :stew: vagrant ssh -c "sudo chef-client"

> Then check the result on the browser: http://[ip]/

### 4th Listing the result

- **chef** :hocho: knife node list
- **chef** :hocho: knife node show node1
- **node** :stew: vagrant ssh -c "ohai" | less
- **chef** :hocho: knife node show node1 -l
- **chef** :hocho: knife node show node1 -a fqdn
- **chef** :hocho: knife search node "*:*" -a fqdn

### 5ft Using attributes

- **chef** :hocho: [manual] Create *apache/attributes/default.rb*

```ruby
default['apache']['indexfile'] = 'index1.html'
```

- **chef** :hocho: [manual] Clone the index.html to index1.html and add something
- **chef** :hocho: [manual] Change the default recipe to use the new property

```ruby
...
cookbook_file '/var/www/html/index.html' do
  source node['apache']['indexfile']
...
```

- **chef** :hocho: knife cookbook upload apache
- **node** :stew: vagrant ssh -c "sudo chef-client"

> Then check the result on the browser: http://[ip]/

### 6th Creating new cookbooks

- **chef** :hocho: knife cookbook create motd
- **chef** :hocho: [manual] Create *motd/attributes/default.rb*

```ruby
default['motd']['company'] = 'Chef'
```

- **chef** :hocho: [manual] Add a template to the recipe

```ruby
template '/etc/motd' do
  source 'motd.erb'
  mode '0644'
end
```

- **chef** :hocho: [manual] Create *motd/template/default/motd.erb*

```ruby
This server is property of <%= node['motd']['company'] %>
<% if node['pci']['in_scope'] -%>
  This server is in-scope for PCI compliance
<% end -%>
```

- **chef** :hocho: knife cookbook upload motd
- **chef** :hocho: knife cookbook create pci
- **chef** :hocho: [manual] Create *pci/attributes/default.rb*

```ruby
default['pci']['in_scope'] = true
```

- **chef** :hocho: knife cookbook upload pci
- **chef** :hocho: knife node run_list add node1 "recipe[motd]"
- **node** :stew: vagrant ssh -c "sudo chef-client"

> This will fail because the pci is not associated to motd



## Troubleshooting

- To solve the clock problem that happens on Mac, put this line in the *Vagrantfile*.

```bash
config.vm.provision :shell, :inline => "sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime", run: "always"
```

- To solve the problem with the kitchen about the conflicts of gems, just drop the file *~/.checfdk2*.
