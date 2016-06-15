# See http://docs.chef.io/config_rb_knife.html for more information on knife configuration options

# edit this or dowload the skeleton from your account, I will let with my local
# configurations as a reference only
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "voiski"
client_key               "#{current_dir}/voiski.pem"
validation_client_name   "ac-chef-avoiski-validator"
validation_key           "#{current_dir}/ac-chef-avoiski-validator.pem"
chef_server_url          "https://api.chef.io/organizations/ac-chef-avoiski"
cookbook_path            ["#{current_dir}/../cookbooks"]
