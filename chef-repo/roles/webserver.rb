name 'webserver'
description 'web Server'
run_list 'role[base]','recipe[apache]'
default_attributes({
                     apache: {
                       sites: {
                         admin: {
                           port: 8000
                         },
                         bears: {
                           port: 8001
                         }
                       }
                     }
})
