## Cookbook Name:: deploy-drupal
## Attribute:: install

# MySQL credentials
default['deploy-drupal']['install']['db_user']  = 'drupal'
default['deploy-drupal']['install']['db_pass']  = 'drupal'
default['deploy-drupal']['install']['db_name']  = 'drupal'

# Drupal user one
default['deploy-drupal']['install']['admin_user'] = 'admin'
default['deploy-drupal']['install']['admin_pass'] = 'admin'

# path to sql dump file (can be .sql.gz) to populate the database
# can be absolute or relative to project root
default['deploy-drupal']['install']['sql_dump'] = ''
# path to bash script file to be executed after installation
# can be absolute or relative to project root
default['deploy-drupal']['install']['script'] = ''
# path to custom file to be apended to local.settings.php
# can be absolute or relative to project root
default['deploy-drupal']['install']['custom_settings'] = ''
