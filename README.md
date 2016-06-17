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

- **node** :stew: vagrant destroy
- **node** :stew: vagrant up
- **node** :stew: vagrant ssh
- **node** :stew: ip addr list
- **chef** :hocho: knife list
- **chef** :hocho: knife client list
- **node** :stew: new_ip=$(vagrant ssh -c "ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//'")
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
- **chef** :hocho: knife search node '*:*' -a fqdn




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
- **chef** :hocho: echo "default['motd']['company'] = 'Chef'" >> cookbooks/motd/attributes/default.rb
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
- **chef** :hocho: echo "default['pci']['in_scope'] = true" >> cookbooks/pci/attributes/default.rb
- **chef** :hocho: knife cookbook upload pci
- **chef** :hocho: knife node run_list add node1 "recipe[motd]"
- **node** :stew: vagrant ssh -c "sudo chef-client"

> This will fail because the pci is not associated to motd

- **chef** :hocho: echo "depends          'pci'" >> cookbooks/motd/metadata.rb
- **chef** :hocho: knife cookbook upload motd
- **node** :stew: vagrant ssh -c "sudo chef-client"

> Run `vagrant ssh` to see the message after the login




### 7th Notifications

- **chef** :hocho: echo "default['apache']['sites']['clowns'] = { 'port' => 80 }" >> cookbooks/apache/attributes/default.rb
- **chef** :hocho: echo "default['apache']['sites']['bears'] = { 'port' => 81 }" >> cookbooks/apache/attributes/default.rb
- **chef** :hocho: [manual] Disable the default virtual host at *apache/recipes/default.rb*

```ruby
# Disable the default virtual host
execute 'mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.disable' do
  only_if do
    File.exist? '/etc/httpd/conf.d/welcome.conf'
  end
  notifies :restart, 'service[httpd]'
end
```
- **chef** :hocho: [manual] Remove the cookbook_file block from *apache/recipes/default.rb*
- **chef** :hocho: [manual] Add the new sites in *apache/recipes/default.rb*

```ruby
# Iterate over the apache sites
node['apache']['sites'].each do |site_name,site_data|
  # Set the document root
  document_root = "/var/www/html/#{site_name}"

  template "/etc/httpd/conf.d/#{site_name}.conf" do
    source 'custom.erb'
    mode '0644'
    variables(
      document_root: document_root,
      port: site_data['port']
    )
    notifies :restart, 'service[httpd]'
  end

  directory document_root do
    mode '0755'
    recursive true
  end

  template "#{document_root}/index.html" do
    source 'index.html.erb'
    mode '0644'
    variables(
      site_name: site_name,
      port: site_data['port']
    )
  end
end
```

- **chef** :hocho: [manual] Create template *apache/templates/default/custom.rb* from [gist 8955103](https://gist.github.com/8955103)
- **chef** :hocho: [manual] Create template *apache/templates/default/index.html.rb* from [gist 8955080](https://gist.github.com/8955080)
- **chef** :hocho: knife cookbook upload apache
- **node** :stew: vagrant ssh -c "sudo chef-client"

> This will fail because the custom.rb has a tag without end

- **chef** :hocho: [manual] Fix the template *apache/templates/default/custom.rb*

```ruby
...
<Directory <%= @document_root %> >
...
```

- **chef** :hocho: knife cookbook upload apache
- **node** :stew: vagrant ssh -c "sudo chef-client"

> This will fail because start service is before the template render

- **chef** :hocho: [manual] Move the service block to the end of the file at *apache/recipe/default.rb*

```ruby
...
node['apache']['sites'].each do |site_name,site_data|
...
end

# Service need to start after all the configurations
service 'httpd' do
  action [ :enable, :start ]
end
```

- **chef** :hocho: knife cookbook upload apache
- **node** :stew: vagrant ssh -c "sudo chef-client"

> Then check the result on the browser: http://[ip]/




### 8th Queries

- **chef** :hocho: knife node show node1 -a fqdn -a ipaddress
- **chef** :hocho: knife search node 'ipaddress:10* and platform_family:rhe1'
- **chef** :hocho: [manual] Create recipe *apache/recipes/ip-logger.rb*

```ruby
search('node', 'platform:centos').each do |server|
  log "The CentOS servers in your organization have the following FQDN/IP Addresses:- #{server['fqdn']}/#{server['ipaddress']}"
end
```

- **chef** :hocho: knife cookbook upload apache
- **chef** :hocho: knife node run_list add node1 "recipe[apache::ip-logger]"
- **node** :stew: vagrant ssh -c "sudo chef-client"

> The log will print the message

- **chef** :hocho: knife node run_list remove node1 "recipe[apache::ip-logger]"



### 9th User and groups
- **chef** :hocho: mkdir -p data_bags/users
- **chef** :hocho: knife data_bag create users
- **chef** :hocho: Create the file *data_bags/users/bobo.json*

```json
{
  "id": "bobo",
  "comment": "Bobo T. Chown",
  "uid": 2000,
  "gid": 0,
  "home": "/home/bobo",
  "shell": "/bin/bash"
}
```

- **chef** :hocho: knife data_bag from file users bobo.json
- **chef** :hocho: Create the file *data_bags/users/frank.json*

```json
{
  "id": "frank",
  "comment": "Frank Belson",
  "uid": 2001,
  "gid": 0,
  "home": "/home/frank",
  "shell": "/bin/bash"
}
```

- **chef** :hocho: knife data_bag from file users frank.json
- **chef** :hocho: knife search users '*:*'
- **chef** :hocho: knife search users 'id:bobo' -a shell
- **chef** :hocho: mkdir -p data_bags/groups
- **chef** :hocho: knife data_bag create groups
- **chef** :hocho: Create the file *data_bags/groups/clowns.json*

```json
{
  "id": "clowns",
  "gid": 3000,
  "members": ["bobo","frank"]
}
```

- **chef** :hocho: knife data_bag from file groups clowns.json
- **chef** :hocho: knife search groups '*:*'
- **chef** :hocho: knife cookbook create users
- **chef** :hocho: [manual] Edit the recipe *users/recipes/default.rb*

```ruby
search('users', '*:*').each do |user_data|
  user user_data['id'] do
    comment user_data['comment']
    uid user_data['uid']
    gid user_data['gid']
    home user_data['home']
    shell user_data['shell']
  end
end

include_recipe 'users::groups'
```

- **chef** :hocho: [manual] Create a new recipe *users/recipes/groups.rb*

```ruby
search('groups', '*:*').each do |group_data|
  group group_data['id'] do
    gid group_data['gid']
    members group_data['members']
  end
end
```

- **chef** :hocho: knife cookbook upload users
- **chef** :hocho: knife node run_list add node1 "recipe[users]"
- **node** :stew: vagrant ssh -c "sudo chef-client"
- **node** :stew: vagrant ssh -c "cat /etc/group | grep clowns"
- **node** :stew: vagrant ssh -c "cat /etc/passwd | grep 200"




### 10th Role-based Attributes and Merge Order Precedence







## Troubleshooting

- To solve the clock problem that happens on Mac, put this line in the *Vagrantfile*.

```bash
config.vm.provision :shell, :inline => "sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime", run: "always"
```

- To solve the problem with the kitchen about the conflicts of gems, just drop the file *~/.checfdk2*.


- If you need to destroy and create again
 - **node** :stew: vagrant destroy
 - **node** :stew: vagrant up
 - **node** :stew: new_ip=$(vagrant ssh -c "ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//'")
 - **node** :stew: ssh-keygen -R ${new_ip//[^([:alnum:]|\.)]/}
 - **chef** :hocho: [manual] Drop the node at the chef manager
 - **chef** :hocho: (cd ../chef-repo;knife bootstrap $new_ip --sudo -x vagrant -P vagrant -N "node1")
 - **chef** :hocho: knife node run_list add node1 "recipe[apache]"
 - **chef** :hocho: knife node run_list add node1 "recipe[motd]"
 - **chef** :hocho: knife node run_list add node1 "recipe[apache::ip-logger]"
 - **node** :stew: [inside node as root] echo 'log_level :info' >> /etc/chef/client.rb
 - **node** :stew: vagrant ssh -c "sudo chef-client"
