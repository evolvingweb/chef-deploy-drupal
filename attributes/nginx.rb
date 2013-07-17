## Cookbook Name:: deploy-drupal
## Attribute:: default

default['deploy-drupal']['nginx']['port'] = "80"
default['deploy-drupal']['nginx']['log_format'] =
  '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent ' +
  '"$http_referer" "$http_user_agent" '+
  '"$http_x_forwarded_for" "$http_host" "$proxy_add_x_forwarded_for"'

# list of pcre patterns to deny request if
# any pattern matches the requested file extenstion
default['deploy-drupal']['nginx']['extension_block_list'] =
  [ 'engine','inc','info','install', 'module', 'profile',
    'po','sh', '.*sql','theme','tpl(\.php)?','xtmpl' ]

# list of pcre patterns to deny request if
# any pattern matches the entire request location
default['deploy-drupal']['nginx']['location_block_list'] = 
  [ 'code-style\.pl','Entries.*', 'Repository','Root','Tag', 'Template' ]

# list of pcre patterns to deny request if
# any pattern matches any part of request location
default['deploy-drupal']['nginx']['keyword_block_list'] = ['boost_crawler']

# list of pcre patterns to serve files if
# any pattern matches requested file extension
# ( will be matched against [pattern](\.gz)? )
default['deploy-drupal']['nginx']['static_content'] =
  [ 'jpg','jpeg','gif','png','bmp','ico',
    'pdf','ps','djvu','doc','docx','rtf', 'xls','htm',
    'flv','mp3','wmv','wma','wav','ogg',
    'mpg','mpeg','mpg4','mp4','avi',
    'zip','bz2','tar','tgz','rar']

default['deploy-drupal']['nginx']['root'] = 
  node['deploy-drupal']['deploy_dir'] + "/" +
  node['deploy-drupal']['project_name'] + "/" +
  node['deploy-drupal']['drupal_root_dir']
