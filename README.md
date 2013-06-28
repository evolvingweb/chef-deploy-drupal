## Deploy Drupal Cookbook

[![BuildStatus](https://secure.travis-ci.org/amirkdv/chef-deploy-drupal.png)](http://travis-ci.org/amirkdv/chef-deploy-drupal)

#### Description
Installs, configures, and bootsraps a [Drupal 7](https://drupal.org/drupal-7.0)
site running on MySQL and Apache. The cookbook supports two main use cases:

- You have an **existing** Drupal site (code base and potentially a database SQL dump) and want to
  configure a server to serve your site.
- You want the server to download, bootstrap, and serve a **fresh** installation of
  Drupal 7.

The repository includes an example `Vagrantfile` to test the cookbook. To use
this file:

``` bash

apt-get install vagrant
vagrant plugin install vagrant-berkshelf
vagrant up

```

To test/debug the cookbook you can use `Test-Kitchen` which simply runs the
minitest test cases defined at `files/default/test/*_test.rb`. To get
Test-Kitchen running:

``` bash
bundle install
kitchen test
```

#### Recipes

- `deploy\_drupal::lamp\_stack`: installs infrastructure packages to support
  Apache, MySQL, PHP, and Drush. 
- `deploy\_drupal::pear\_dependencies`: installs PEAR, PECL, and other PHP
  enhancement packages.
- `deploy\_drupal::default`: is the main recipe that loads and installs Drupal 7
  and configures MySQL and Apache to serve the site.

#### Platform
Tested on:
* Ubuntu 12.04

#### Attributes
The following are the main attributes that this cookbook uses:

|     Attribute         |    Default Value    |           Description                   |
| ----------------------|:-------------------:|:--------------------------------------: |
| `codebase_source_path`|      none           | absolute path to existing site codebase
| `site_name`           |   cooked.drupal     | Virtual Host name
| `deploy_directory`    |`/var/shared/sites/[site_name]/site` | Root of served Drupal site
| `apache_port`         |       80            | must be consistent with`node['apache']['listen_ports']`
| `apache_user`         |    `www-data`       |
| `apache_group`        |    `www-data`       |
| `sql_load_file`       |     `''`            | absolute path to existing site SQL dump
| `sql_post_load_script`|     `''`            | absolute path to bash script to be executed after loading SQL dump
| `dev_group`           |     `sudo`          | System group owning site root(excludes `apache_user`)
| `files_path`          |`sites/default/files`| Drupal files directory, relative to site root
| `admin_pass`          |     `admin`         | Drupal site administrator password
| `db_name`             |     `drupal`        | MySQL database used by Drupal
| `mysql_user`          |     `drupal_db`     | MySQL user used by Drupal (`settings.php`)
| `mysql_pass`          |     `drupal_db`     | MySQL password used by Drupal (`settings.php`)

#### Behavior

Currently, the cookbook tries to load an existing site and if it fails due to
the absence of codebase or discrepancies in credentials, it will
download a fresh stable release of Drupal 7 from [drupal.org](http://drupal.org)
and will configure MySQL and Apache, according to cookbook attributes, to serve
a bootstrapped site (no manual installation required).

The expected state after provisioning is as follows:

1. MySQL recognizes a user with provided credentials. The user is granted all privileges on the
database used by Drupal.
1. Apache has a virtual host bound to port
`node['deploy_drupal']['apache_port']` with the name
`node['deploy_drupal']['site_name']` with root directory at
`node['deploy_drupal']['deploy_dir']`.
1. This directory is the root of the installed Drupal site. Ownership and
permission settings of this directory are set as follows:
  1. The user and group owners of all current files and subdirectories are
  `node['deploy_drupal']['apache_user']` and
  `node['deploy_drupal']['dev_group']`, respectively.
  1. The group owner of all files and subdirectories created in the future will be
  `node['deploy_drupal']['dev_group']` (`setgid` flag is set for all files and
  subdirectories). The user owner of future files and directories will depend on the
  default behavior of the system (in all major distributions of Linux `setuid`
  is ignored, and this cookbook, therefore, does not use it).
  1. The permissions for all files and subdirectories are set to `r-- rw- ---`
  and `r-x rwx ---`, respectively. The only exception is the `files`
  directories (attribute `node['deploy_drupal']['files_path']`) and all its
  contents, which has its permissions set to `rwx rwx ---`.
1. A bash utility `drupal-perm.sh` is installed at `/usr/local/bin` that
when invoked from the Drupal root directory, ensures that the ownership and
permission settings described above are in place.
