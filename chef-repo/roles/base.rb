name 'base'
description 'Base Server Role'
run_list "recipe[chef-client::delete_validation]", "recipe[motd]", "recipe[users]"
