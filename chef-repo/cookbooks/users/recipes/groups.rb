#
# Cookbook Name:: users
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

search('groups', '*:*').each do |group_data|
  group group_data['id'] do
    gid group_data['gid']
    members group_data['members']
  end
end
