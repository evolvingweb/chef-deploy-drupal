## Deploy Drupal Cookbook

[![BuildStatus](https://secure.travis-ci.org/amirkdv/chef-deploy-drupal.png)](http://travis-ci.org/amirkdv/chef-deploy-drupal)

#### Description
Installs, configures, and bootsraps a [Drupal 7](https://drupal.org/drupal-7.0)
site running on MySQL and Apache. The cookbook supports two main use cases:

- You have an **existing** Drupal site (code base, database SQL dump, and maybe
  a bash script to run after everything is loaded) and want to
  configure a server to serve your site.
- You want the server to download, bootstrap, and serve a **fresh** installation of
  Drupal 7.

Look at [Attributes](#Attributes) to see how to use each of these use cases.

#### Testing
This repository includes an example `Vagrantfile` to test the cookbook. To use
this file, make sure you have [Vagrant
v2](http://docs.vagrantup.com/v2/installation/) and the
[Vagrant-Berkshelf](https://github.com/riotgames/vagrant-berkshelf) plugin
installed. For the latter, use `vagrant plugin install vagrant-berkshelf`.

Refer to [Vagrant-Drupal](http://github.com/dergachev/vagrant-drupal) for a more
detailed description of how to use this cookbook with Vagrant.

To test/debug the cookbook you can use [Test-Kitchen](https://github.com/opscode/test-kitchen)
which simply runs the
minitest test cases defined at `files/default/test/*_test.rb`. To get
Test-Kitchen running:

``` bash
# inside repo root
bundle install
kitchen test
```

#### Recipes

- `deploy-drupal::lamp_stack`: installs infrastructure packages to support
  Apache, MySQL, PHP, and Drush. 
- `deploy-drupal::pear_dependencies`: installs PEAR, PECL, and other PHP
  enhancement packages.
- `deploy-drupal::default`: is the main recipe that loads and installs Drupal 7
  and configures MySQL and Apache to serve the site.

#### Platform
Tested on:
* Ubuntu 12.04

#### Attributes
The following are the main attributes that this cookbook uses. All attributes mentioned
below can be accessed in the cookbook via 
`node['deploy_drupal']['<attribute_name>']`:


|   Attribute Name    |Default |           Description           |
| --------------------|:------:|:------------------------------: |
|`source_project_path`| `''`   | absolute path to existing project
|`source_site_path`   | `'site'` | Drupal site root (in source & in deployment), relative to project path
|`sql_load_file`      |`''`    | path to SQL dump, relative to project path
|`post_script_file`   |`''`|path to post-install script, relative to project path
|`site_files_path`    |`sites/default/files`| Drupal "files", relative to site root
|`deploy_base_path`   |`/var/shared/sites`| Directory containing differentDrupal projects
|`site_name`          |`'cooked.drupal'`| Virtual Host name and directory in deploy base path
|`apache_port`        |80      | must be consistent with`node['apache']['listen_ports']`
|`apache_user`        |`www-data` |
|`apache_group`       |`www-data` |
|`dev_group`          |`sudo`     | System group owning site root (excludes `apache_user`)
|`admin_pass`         |`admin`    | Drupal site administrator password
|`db_name`            |`drupal`   | MySQL database used by Drupal
|`mysql_user`         |`drupal_db`| MySQL user used by Drupal
|`mysql_pass`         |`drupal_db`| MySQL password used by Drupal

#### Behavior

Currently, the cookbook tries to load an existing site and if it fails due to
the absence of codebase or discrepancies in credentials, it will
download a fresh stable release of Drupal 7 from [drupal.org](http://drupal.org)
and will configure MySQL and Apache, according to cookbook attributes, to serve
a bootstrapped site (no manual installation required).

The expected state after provisioning is as follows:

1. The following directory structure holds in the provisioned machine:
  - `deploy_base_path`
      - `site_name`
          - `source_site_path`
              - `index.php`
              - `includes`
              - `modules`
              - `sites`
              - `themes`
              - ...
          - `db`
              - `dump.sql.gz`
          - `scripts`
              - `post-install-script.sh`

1. Note that `db` and `scripts` subdirectories are not controlled by the cookbook,
and will be copied over along with everything else that might exist in the
`source_project_path` directory.
1. MySQL recognizes a user with username `mysql_user`, identified by
`mysql_password`. The user is granted **all** privileges on the database
`db_name`.
1. Apache has a virtual host bound to port `apache_port` with the name
`site_name`. The virtual host has its root directory at
`<deploy_base_path>/<site_name>/source`.
1. The `<deploy_base_path>/<site_name>` directory is the root of the installed Drupal 
project (the actual site is in the `site` subdirectory). Ownership and
permission settings of this directory are set as follows:
  1. The user and group owners of all current files and subdirectories are
  `apache_user` and `dev_group`, respectively.
  1. The group owner of all files and subdirectories created in the future will be
  `dev_group` (the `setgid` flag is set for all subdirectories). The user owner 
  of future files and directories will depend on the
  default behavior of the system (in all major distributions of Linux `setuid`
  is ignored, and this cookbook, therefore, does not use it).
  1. The permissions for all files and subdirectories are set to `r-- rw- ---`
  and `r-x rwx ---`, respectively. The only exception is the "files"
  directories (refer to the `site_files_path` attribute) and all its
  contents, which has its permissions set to `rwx rwx ---`.
1. A bash utility `drupal-perm.sh` is installed at `/usr/local/bin` that
when invoked from the project root directory, ensures that the ownership and
permission settings described above are in place.
