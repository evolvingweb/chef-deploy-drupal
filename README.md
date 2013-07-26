## Deploy Drupal Cookbook

[![BuildStatus](https://secure.travis-ci.org/amirkdv/chef-deploy-drupal.png)](http://travis-ci.org/amirkdv/chef-deploy-drupal)

#### Description
Installs, configures, and bootsraps a [Drupal 6/7](https://drupal.org)
site running on MySQL and Apache, and if desired with an Nginx reverse proxy. 
The cookbook supports two main use cases:

- You have an **existing** Drupal site (code base, database SQL dump, and maybe
  a bash script to run after everything is loaded) and want to
  configure a server to serve your site.
- You want the server to download, install, and serve a **fresh** installation of
  Drupal 6/7.

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

The following are the main attributes that this cookbook uses. All attributes mentioned
below can be accessed in the cookbook via 
`node['deploy_drupal']['<attribute_name>']`:


|   Attribute Name    |Default |           Description           |
| --------------------|:------:|:------------------------------: |
|`get_project`| `''`| path to existing project or url to existing git repo (refer to Recipes for usage)
|`drupal_dl_version`| `drupal-7`| Drupal version to download if no existing site is found (refer to Recipes for usage)
|`sql_load_file`|`''`     | path to SQL dump, absolute **or** relative to project root
|`post_install_script`|`''` |path to post-install script, absolute **or** relative to project root
|`drupal_root_dir`|`site`| name (no path) of Drupal site root directory (in source & in deployment), relative to project root
|`drupal_files_dir`|`sites/default/files`| Drupal "files", relative to site root
|`deploy_dir`|`/var/shared/sites`| absolute path to deployment directory
|`project_name`|`cooked.drupal`| Virtual Host name and deployed project directory (relative inside `deploy_dir`)
|`admin_user`   |`admin`  | username for "user one" in the installed site
|`admin_user`   |`admin`  | password for "user one" in the installed site
|`apache_port`|80       | must be consistent with`node['apache']['listen_ports']`
|`admin_pass` |`admin`  | Drupal site administrator password
|`dev_group_name` |`root` | System group owning site root (user owner is `node['apache']['user']`), must be already recognized by the operating system
|`db_name`      |`drupal` | MySQL database used by Drupal
|`mysql_user`   |`drupal_db`| MySQL user used by Drupal
|`mysql_pass`   |`drupal_db`| MySQL password used by Drupal

## Recipes
In what follows, a **project** is a directory containing a Drupal site root
directory (`drupal_root_dir`), and potentially database dumps, scripts
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
1. `N.x.y` will try and download the exact provided version.

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

#### `deplpoy-drupal::prepare`
Prepares the machine for Drupal installation: configures apache
vhost, and if necessary, creates Drupal MySQL user with appropriate privileges,
and, again, if necessary, creates an empty Drupal database.
This recipe ensures that:

* MySQL recognizes a user with username `<db_user>`, identified by
`<db_pass>`. The user is granted **all** privileges on the database
`db_name`.
* Apache has a virtual host bound to port `<apache_port>` with the name
`<project_name>`. The virtual host has its root directory at
`<drupal_root>`.

Additionally, this
recipe installs two utility bash scripts under `/usr/local/bin/`:

* `drupal-perm`: fixes the fily system permissions and ownership of the
project directory (automatically invoked in the `install` recipe). Refer to the
description of the `deploy-drupal::install` recipe, below, for more information
about the behavior of this script.
* `drupal-reset`: takes a `drush archive-dump` of the existing Drupal site,
and reverts the system back to its state prior to Drupal
installation: destroys project directory at `<project_root>`,
drops the Drupal Database `<db_name>` and MySQL user `<db_user>`.

#### `deploy-drupal::install`
Makes sure that the Drupal site is connected to a Drupal database. Drush
site-install is used **only** if the loaded (or downloaded) site does not have
valid credentials **and** if the database `<db_name>` is entirely empty (no
tables).

It also populates the database if a database dump is found at
`sql_dump`. This attribute can be an absolute path in local file system
(for example, when you do not have an existing project), or
relative to the project root (and therefore sought at
`<project_root>/<sql_dump>`). Again, the database dump is
**only** used if the `<db_name>` MySQL database is entirely empty.

After installation, this recipe will run an optional bash script that you might
provide under `post_install_script`, which, similar to `sql_load_file`, can be
absolute or relative to project root.

After installation, the expected state is as follows:

1. The installed Drupal site recognizes `<admin_user>` (with password
`<admin_pass>`) as "user one".
1. The following directory structure holds in the provisioned machine:
    - `/var/shared/sites/<project_name>`
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
the `<get_project_from[:path]>` directory, or the `<get_project_from[:git]>`
repo at `<deploy_dir>/<project_name>`
1. The provided `dev_group_name` 
system to be provisioned. This user group will own the project root directory. 
1. Ownership and permission settings of the deployed project root directory
(loated at `<deploy_dir>/<project_name>`) are set as follows:
  1. The user and group owners of all current files and subdirectories are
  `<node['apache']['user']>` and `<dev_group_name>`, respectively.
  1. The group owner of all files and subdirectories created in the future will be
  `dev_group` (the `setgid` flag is set for all subdirectories). The user owner 
  of future files and directories will depend on the
  default behavior of the system (in all major distributions of Linux `setuid`
  is ignored, and this cookbook, therefore, does not use it).
  1. The permissions for all files and subdirectories are set to `r-- rw- ---`
  and `r-x rwx ---`, respectively. The only exception is the "files"
  directories (refer to the `drupal_files_dir` attribute) and all its
  contents, which has its permissions set to `rwx rwx ---`.

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
