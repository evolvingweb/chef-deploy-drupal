## Cookbook Name:: deploy-drupal
## Recipe:: install
##
## make sure drupal is connected to database
##  1. drush si (if not connected and empty db)
##  2. load db from dump (if db empty)
##  3. run post-install script
##  4. fix file permissions
##  5. clear drush cache

   # assemble all necessary query strings and paths
# requires drush 6
DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_dir']   + "/" +
                      node['deploy-drupal']['project_name']

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR   + "/" +
                      node['deploy-drupal']['drupal_root_dir']

DRUSH               = "drush --root='#{DEPLOY_SITE_DIR}'"

# FIXME this is not robust: it will break if the credentials in 
# settings.php work with the database but do not match the
# credentials in Chef attributes.
DRUPAL_DISCONNECTED = [ DRUSH, "status",
                        "--fields=db-status",
                        "| grep Connected",
                        "| wc -l | xargs test 0 -eq"
                      ].join(' ')

DB_ROOT_CONNECTION  = [ "mysql",
                        "--user='root'",
                        "--host='localhost'",
                        "--password='#{node['mysql']['server_root_password']}'"
                      ].join(' ')

# mysql specific query to determine whether the Drupal database has
# any tables (exits with 0 if there is any table)
DB_FULL             = [ DB_ROOT_CONNECTION, "-e \"",
                        "SELECT * FROM information_schema.tables",
                        "WHERE table_type = 'BASE TABLE'",
                        "AND table_schema = '#{node['deploy-drupal']['db_name']}';\"",
                        "| wc -l | xargs test 0 -ne"
                      ].join(' ')

DRUSH_DB_URL        = "mysql://" +
                        node['deploy-drupal']['mysql_user'] + ":'" +
                        node['deploy-drupal']['mysql_pass'] + "'@localhost/" +
                        node['deploy-drupal']['db_name']

# Using zless instead of cat/zcat to optionally support gzipped files
# "`drush sql-connect`" because "drush sqlc" returns 0 even on connection failure
DRUSH_SQL_LOAD      =   "zless '#{node['deploy-drupal']['sql_load_file']}' " +
                        "| `#{DRUSH} sql-connect`"

# fixes sendmail error https://drupal.org/node/1826652#comment-6706102
DRUSH_SI            = [ "php -d sendmail_path=/bin/true",
                        "/usr/share/php/drush/drush.php",
                        "--root='#{DEPLOY_SITE_DIR}'",
                        "site-install --debug -y",
                        "--account-name=#{node['deploy-drupal']['admin_user']}",
                        "--account-pass=#{node['deploy-drupal']['admin_pass']}",
                        "--db-url=#{DRUSH_DB_URL}",
                        "--site-name='#{node['deploy-drupal']['project_name']}'"
                      ].join(' ')

# make sure the site directory exists
directory DEPLOY_SITE_DIR + "/" + node['deploy-drupal']['drupal_files_dir'] do
  recursive true
end


# TODO must raise exception if db is full but Drupal is not connected
# install Drupal Site
execute "install-disconnected-empty-db-site" do
  command DRUSH_SI
  only_if DRUPAL_DISCONNECTED
  not_if DB_FULL
  not_if  "test -f '#{node['deploy-drupal']['sql_load_file']}'", :cwd => DEPLOY_PROJECT_DIR
  notifies :run, "execute[populate-fresh-installation-db]", :immediately
  notifies :run, "execute[drush-suppress-http-status-error]", :delayed
end

# load sql dump, if any, after fresh installation
# obliterates database regardless of content, 
# should only be notified by install-disconnected-empty-db-site
execute "populate-fresh-installation-db" do
  # DRUSH_SQL_LOAD has to be run in the project root,
  # since db script path might be relative
  cwd DEPLOY_PROJECT_DIR
  command DRUSH_SQL_LOAD
  only_if  "test -f '#{node['deploy-drupal']['sql_load_file']}'", :cwd => DEPLOY_PROJECT_DIR
  action :nothing
  notifies :run, "execute[run-post-install-script]"
end

# load sql dump, if any, if Database is still empty
execute "populate-db" do
  # DRUSH_SQL_LOAD has to be run in the project root,
  # since db script path might be relative
  cwd DEPLOY_PROJECT_DIR
  command DRUSH_SQL_LOAD
  only_if  "test -f '#{node['deploy-drupal']['sql_load_file']}'", :cwd => DEPLOY_PROJECT_DIR
  not_if DB_FULL
  notifies :run, "execute[drush-cache-clear]", :immediately
  notifies :run, "execute[run-post-install-script]", :delayed
  notifies :run, "execute[drush-suppress-http-status-error]", :delayed
end

execute "run-post-install-script" do
  cwd DEPLOY_PROJECT_DIR
  command "bash '#{node['deploy-drupal']['post_install_script']}'"
  only_if "test -f '#{node['deploy-drupal']['post_install_script']}'", :cwd => DEPLOY_PROJECT_DIR
  action :nothing
end

# fix permissions of project root
execute "fix-drupal-permissions" do
  command "bash drupal-perm"
end

# TODO should only be used when Drupal is served through a forwarded port
execute "drush-suppress-http-status-error" do
  command "#{DRUSH} vset -y drupal_http_request_fails FALSE"
  action :nothing
end

# ignore_failure is a workaround for the following errors:
#    You have an error in your SQL syntax; check the manual that              [error]
#    corresponds to your MySQL server version for the right syntax to use
#    near &#039;) ORDER BY fit DESC LIMIT 0, 1&#039; at line 1
#      query: SELECT * FROM menu_router WHERE path IN () ORDER BY fit DESC
#    LIMIT 0, 1 in /var/shared/sites/muhc/site/includes/menu.inc on line
#    317.
execute "drush-cache-clear" do
  command "#{DRUSH} cache-clear all"
  ignore_failure true
  action :nothing
end
