#
# Cookbook Name:: apache
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
package 'httpd' do
 action :install
end

#Disable the default virtual host
execute 'mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.disable' do
  only_if do
    File.exist? '/etc/httpd/conf.d/welcome.conf'
  end
  notifies :restart, 'service[httpd]'
end

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

service 'httpd' do
  action [ :enable, :start ]
end
