## Deploy Drupal Cookbook

[![BuildStatus](https://secure.travis-ci.org/amirkdv/chef-deploy-drupal.png)](http://travis-ci.org/amirkdv/chef-deploy-drupal)

#### Description
Installs, configures, and bootsraps a [Drupal 6/7](https://drupal.org)
site running on MySQL and Apache, and if desired with an Nginx reverse proxy. 
The cookbook supports two main use cases:

- You have an **existing** Drupal site (code base, database SQL dump, and maybe
  a bash script to run after everything is loaded) and want to
  configure a server to serve your site.
- You want to quickly configure a server that serves a fresh installation of
  Drupal.

To see how you can load an existing code base (from local filesystem or from a
git repo) and populate the Drupal database with an existing database dump, refer
to the **recipes** and **attributes** sections below.

#### Requirements
Chef >= 11.0.0

#### Platforms
Testing on this cookbook is not yet complete. Currently, the cookbook is
tested on:
* Ubuntu 12.04

#### Usage with Vagrant

This repository includes an example `Vagrantfile` that spins up a virtual machine
serving Drupal. To use this file, make sure you have [Vagrant
v2](http://docs.vagrantup.com/v2/installation/); do not install it as a Ruby gem
since Vagrant is [not a gem](http://mitchellh.com/abandoning-rubygems) as of version
1.1+ (i.e v2). You will also need to have the
[Vagrant-Berkshelf](https://github.com/riotgames/vagrant-berkshelf) plugin
installed:

``` bash
# have Vagrant v2 installed
vagrant plugin install vagrant-berkshelf
```

Once you have these ready, clone this repository, `cd` to the repo root, and:

``` bash
bundle install
vagrant up
```

For a more
detailed description of how to use this cookbook for local development with
Vagrant, you can refer to the
[Vagrant-Drupal](http://github.com/dergachev/vagrant-drupal) project 

## Attributes
The cookbook tries to load an existing site and if it fails to do so, it will
download a fresh stable release of Drupal 7 from [drupal.org](http://drupal.org)
and will configure MySQL and Apache, according to cookbook attributes, to serve
a installed site (no manual installation required).

Cookbook attributes are divided to 4 groups (`default`, `install`, `get_project`,
and `nginx`). All attributes mentioned below can be accessed in the cookbook via 
`node['deploy_drupal']['<attribute_group>']['<attribute_name>']`:

* Core attributes (`default`):

|   Attribute Name    |Default |           Description           |
| --------------------|:------:|:------------------------------: |
|`version`| `7`| Drupal version to be configured and/or downloaded, can be `N`, `N.x`, or `N.x.y`
|`apache_port`| `80`| Port to which Apache virtual host for Drupal listens, must be consistent with `node['apache']['listen_ports']`
|`dev_group`|`'root'`| user group owning drupal codebase files, cookbook does *not* create the group if it does not exist
|`project_name`| `'cooked.drupal'` | Used as project identifier in configuration files: Apache VHost name, Nginx site name
|`project_root`| `/var/shared/sites/<project_name>` | absolute path to project directory
|`drupal_root` | r.f `attributes/default.rb` | absolute path to Drupal site, if `['get_project']['git_repo']` or `['get_project']['path']` is set, defaults to `<project_root>/X` where `X` is the Drupal root directory in existing project, otherwise defaults to `<project_root>/site`
|`writable_dirs`|   `[ '/sites/default/files' ]` | array of relative paths (to `drupal_root`) to directories in Drupal root to which Apache will be granted write access
|`ini_directives`| `[ ]` | hash containing PHP ini directives that will be written to `deploy-drupal.ini` in the PHP extension directory in the form `<key>=<value>`

* Project attributes (`get_project`):
 
|   Attribute Name    |Default |           Description           |
| --------------------|:------:|:------------------------------: |
|`path` | `''` | absolute path to a project directory in filesystem, will be copied to `<project_root>`, will be ignored if `git_repo` is specified.
|`git_repo`| `''` | git URL to a project repository, will be cloned to `<project_root>`
|`git_branch` | `master` | branch to checkout from project repository
|`site_dir` | `site` | Drupal site directory relative to project path, will be disregarded if no path or git url is specified (Drupal will be downloaded to `<project_root>/site`

* Installation attributes (`install`):

|   Attribute Name    |Default |           Description           |
| --------------------|:------:|:------------------------------: |
| `db_user`| `drupal` | Database user for Drupal
| `db_pass`| `drupal` | Database password for Drupal user
| `db_name`| `drupal` | Drupal Database name
| `admin_user`| `admin` | username for Drupal user one
| `admin_pass`| `admin` | password for Drupal user one
| `sql_dump`| `''` | path to sql dump file (can be `.sql.gz`) to populate the database, can be absolute *or* relative to project root
| `script` | `''` | path to bash script file to be executed after installation, can be absolute *or* relative to project root

* Nginx attributes (`nginx`):

|   Attribute Name    |Default |           Description           |
| --------------------|:------:|:------------------------------: |
|`port` | `80` | defaults to the same port as Apache, but `deploy-drupal::nginx` is not included in the default recipe, must update `apache_port` if setting up Nginx
|`log_format` | r.f `attributes/nginx.rb` | log format for the `<project_name>` Nginx site
|`extension_block_list` | r.f `attributes/nginx.rb` | list of PCRE patterns to deny request if any pattern matches the requested file extenstion
|`location_block_list` | r.f `attributes/nginx.rb` | list of PCRE patterns to deny request if any pattern matches the entire request location
|`keyword_block_list` | r.f `attributes/nginx.rb` | list of pcre patterns to deny request if any pattern matches any part of request location
|`static_content` | r.f `attributes/nginx.rb` | list of pcre patterns to serve files if any pattern matches requested file extension (will be matched against `[<pattern>](\.gz)?` )
|`custom_site_file` | `''` | path to file to be copied to the Nginx site file, can be absolute *or* relative to project root (if this file exists, the cookbook would not add any content to the site file)

* APC configuration attributes (`apc_directives`):

|   Attribute Name    |Default |           Description           |
| --------------------|:------:|:------------------------------: |
|`shm_size` | `64M` | (C.f `ini_directives` above) hash containing PHP ini directives for APC that will be written to `apc.ini` in the PHP extension directory in the form `apc.<key>=<value>`

**note**: The contents of the APC directives hash are treated in a slightly different
fashion from the contents of `ini_directives`: A `<key,value>` pair in `ini_directives`
creates the line `key=value` in 
`deploy-drupal.ini` where as a pair in `apc_directives` create the line `apc.key=value`.
This behavior is inherited from the PHP cookbook (`php_pear` LWRP) which writes
extension directives in the `extension.key=value`  form. Furthermore, as in the
case of `ini_directives` attribute, you can add any APC related directive to this hash.

## Recipes
In what follows, a **project** is a directory containing a Drupal site root
directory (`drupal_root`), and potentially database dumps, scripts
and other configuration files.

#### `deploy-drupal::dependencies`
Includes dependency cookbooks, installs lamp stack packages to get Apache, MySQL, PHP, and Drush running.

#### `deploy-drupal::download_drupal`
Downloads drupal if no existing project is found. This recipe
**only** downloads Drupal if both attributes `['get_project']['path']` and
`['get_project']['path']` are left empty (as they are by default). This recipe
will simply download and untar Drupal to a temporary directory and assign the
path to this directory to `['get_project']['path']`. This recipe uses the
`version` attribute which defaults to `'7'`. To use this
attribute, you should provide the recipe with drupal version that

1. `7` will download the latest recommended Drupal7 release (`'7.22'` as of now),
1. `6` will download the latest recommended Drupal6 release (`'6.28'` as of
now),
1. `N.x` and `N.x.y` will try to download the exact provided version.

This recipe does not by any means rely on cookbook dependencies and can be
invoked independently (without having `deploy-drupal::dependencies` preceding
it in the run list)

#### `deploy-drupal::get_project`
Loads existing project, if any, and makes sure the 
project directory skeleton is created in deployment. To specify existing
projects, the `get_project` attribute should be used:

``` ruby
# use git repo as project
:git_repo => "url://to/git/repository.git",
:git_branch => "foo" # defaults to "master"

# use project in local file system
:path => "path/to/existing/project"

```

An existing Drupal site is sought either at the absolute path
`<get_project_from[:path]>` or at git url `<get_project_from[:git]>`.
If such project is found, it will be deployed at `<deploy_dir>/<project_name>`

This recipes ensures that the directories `<deploy_dir>/<project_name>` and
`<deploy_dir>/<project_name>/<drupal_root_dir>` are created.

#### `deplpoy-drupal::install`
Installs Drupal and utility scripts on the machine: configures apache
vhost, if necessary, creates Drupal MySQL user with appropriate privileges,
and, populates the database (first, if dump file is provided, otherwise with
`drush site-install`).

This recipe ensures that:
* MySQL recognizes a user with username `<db_user>`, identified by
`<db_pass>`. The user is granted **all** privileges on the database
`db_name`.
* Apache has a virtual host bound to port `<apache_port>` with the name
`<project_name>`. The virtual host has its root directory at
`<drupal_root>`.
* Drupal root directory contains valid credentials to connect to its database. A
`settings.local.php` file is generated according to Drupal version and
provided credentials. *Note*: `settings.php` is created and configured to
include `settings.local.php` *only if* the provided code base does not include a
`settings.php` file (typically only happens if Drupal is downloaded).

Additionally, this recipe installs two utility bash scripts under `/usr/local/bin/`:

* `drupal-perm`: fixes the fily system permissions and ownership of the
project directory (automatically invoked after database population).
* `drupal-reset`: takes a `drush archive-dump` of the existing Drupal site,
and reverts the system back to its state prior to Drupal
installation: destroys project directory at `<project_root>`,
drops the Drupal Database `<db_name>` and MySQL user `<db_user>`.

Note that `drush site-install` is used **only** if the the database 
`<db_name>` is entirely empty (no tables) and no database dump file is provided
(or the dump file is empty). `site-install` is not invoked for
generating credentials in `settings.php`. *Note*: The database dump is used
*only if* the `<db_name>` MySQL database is entirely empty.

After installation, this recipe will optionally run a bash script that you might
provide as the attribute `['deploy-drupal']['install']['script']`.

After installation, the expected state is as follows:

1. The installed Drupal site recognizes `<admin_user>` (with password
`<admin_pass>`) as "user one".
1. The following directory structure holds in the provisioned machine:
    - `<project_root>`
        - `<drupal_root>`
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

1. Note that `db` and `scripts` are just example subdirectories and are not
controlled by the cookbook. You will be able to find the entire contents of
the `<['get_project']['path']>` directory, or the
`<['get_project']['git_repo']>` git repo (`git_branch` will be checked out) `<project_root>`.
1. The provided `dev_group` user group will own the project root directory. 
1. Ownership and permission settings of the deployed project root directory
(loated at `<project_root>`) are set as follows:
  1. Only the group owner of `<project_root>` is set (`<dev_group>`).
  1. The user and group owners of all files and subdirectories under
  `<drupal_root>` are
  `<node['apache']['user']>` and `<dev_group>`, respectively.
  1. The group owner of all files and subdirectories created in the future will be
  `dev_group` (the `setgid` flag is set for all subdirectories). The user owner 
  of future files and directories will depend on the
  default behavior of the system (in all major distributions of Linux `setuid`
  is ignored, and this cookbook, therefore, does not use it).
  1. The permissions for all files and subdirectories are set to `r-- rw- ---`
  and `r-x rwx ---`, respectively. The only exception is the "files"
  directories (refer to the `drupal_files_dir` attribute) and all its
  contents, which has its permissions set to `rwx rwx ---`.
  1. `node['apache']['user']` will be grant write access (`chmod -R u+w`) to all
  directories specified in `<writable_dirs>`.

#### Testing/Development
1. The cookbook includes test cases written using the
[minitest-handler-cookbook](https://github.com/btm/minitest-handler-cookbook).
You can add test cases to `files/default/test/*_test.rb`.
1. Automated testing of different combinations platforms and existing machine
state is done using [Test-Kitchen](https://github.com/opscode/test-kitchen).
You can define more tests in the `.kitchen.yml` file. The existing
`.kitchen.yml` file uses the [Vagrant driver](https://github.com/portertech/kitchen-vagrant)
for Test-Kitchen, also included in the Gemfile. To get Test-Kitchen to run 
your tests against the cookbook:

        git clone [this-repo] && cd [this-repo]
        # install and kitchen-vagrant
        bundle install
        kitchen test 

1. To speed up debugging/testing the included `Vagrantfile` uses a Vagrant box named
`precise64-dev` which is merely a `precise64` VM having had
`deploy-drupal::dependencies` run against it. You can checkout the list of all
the packages and gems installed on this box
[here](https://s3.amazonaws.com/vagrant-drupal/precise64-dev.txt)
1. Note that the `vagrant-berkshelf` plugin should
be installed using `vagrant plugin install` and not as an independent Ruby gem.
1. Right now, [Travis-CI](https://travis-ci.org/) is being used only minimally;
only `foodcritic` and `knife cookbook test` are run against the cookbook. More
continuous integrantion to come ... 
