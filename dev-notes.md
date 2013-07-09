# How This Works

## cookbook (dependency) management
[berkshelf](http://berkshelf.com/) provides the same functionality as
[librarian-chef](https://github.com/applicationsonline/librarian-chef) in that it follows
the information provided in a `berksfile` (almost equivalent of librarian-chef's
`cheffile`) and loads all the required cookbooks. the main difference between
the two, aside from berkshelf's [superior
integration](https://github.com/riotgames/vagrant-berkshelf) with vagrant, is
that berkshelf has more awareness of its surrounding environment and is
integrated more smoothly within a cookbook.

#### the `berksfile`
`berks install` follows the directives in your `berksfile` to load cookbooks
(from community api, local system, or git repo). you can also group cookbooks
together (using `group` blocks) and use this grouping at installation time (when
you perform `berks install`), to exclude or include certain cookbooks using
options like `--without` and `--only`. 

you can use the `site` directive in your `berksfile` to indicate a community
site api to be used by berkshelf. for using the opscode's newest community api
you can simply use `:opscode` (instead of
`http://cookbooks.opscode.com/api/v1/cookbooks`). cookbooks can also be loaded
from other sources using `:path` (local) and `:git` (and potentially `:rel`)
options.

the convention has become to leave a `berksfile` in the root of the cookbook,
even when there is no provisioning setup. the immediate use case for this is to
provide alternative (non-community) sources for specific dependencies. but also
to use the `metadata` keyword to tell berkshelf that it should also load the
dependencies mentioned in the `metadata.rb` file of the cookbook (this only
works if `berksfile` is in the cookbook root).

#### berkshelf workflow
berks, as opposed to librarian-chef, maintains some sort of state of its own by
installing cookbooks to **its** directory (stored in `berkshelf_path`, by
default `~/.berkshelf/`). all cookbooks installed in this way can be 
catalogued using `berks shelf list`. although apparently you can get 
`berks install` to put the cookbooks in a
custom folder (relative to the directory where install is invoked `berks install
-p /path/to/cookbooks`). in the
latter case, berkshelf will leave a copy of all cookbooks it installs in the
path you specify, **in addition** to installing them, for further reuse, in its
directory.

furthermore, the customary way of using berkshelf is to allow it to install
dependencies on the node as needed. so you provide the node with all *your*
cookbooks and use berkshelf on the node to load all external dependencies
before provisioning with chef.

#### berkshelf and vagrant
berkshelf works easily with vagrant through a plugin (`vagrant plugin install
vagrant-berkshelf`). note that this does install a gem named
`vagrant-berkshelf`, but installing the gem directly (without `vagrant plugin
install` would not let vagrant know about the plugin.
once the plugin is installed, vagrant **by default** calls berkshelf before
provisioning. if you want vagrant to not use the plugin you should
indicate so in the `vagrantfile` by adding `config.berkshelf.enabled = false` to
your `vagrant.configure("2")` block.  once you have done that, the plugin would
allow vagrant to access berkshelf's cookbook directory without the `vagrantfile`
having to contain a `chef.cookbooks_path` directive (this attribute is, in fact,
[hijacked](http://berkshelf.com/#chef_solo_provisioner) by vagrant-berkshelf in
solo provisioning). all cookbooks that berkshelf has installed (in
`~/.berkshelf/`) can be used, and any non-installed cookbooks indicated in the
`berksfile` will be downloaded and available to the vm, as usual, at
`/tmp/vagrant-chef-1/chef-solo-1/cookbooks/`.

#### Minimal Setup
Using Vagrant, Berkshelf, and Chef you can create a configured
virtual machine using only [two configuration
files](http://github.com/dergachev/vagrant-drupal); all you need is a `Berksfile` and a
`Vagrantfile`. 

## Note on Software Versions

#### Vagrant v1, v2
Vagrant v1 refers to `v1.0.x` and Vagrant v2 refers to
anything late, i.e `v1.1+`. Furthermore, Vagrant v1 is provided as a Rubygem (soon to be
[discontinuted](http://mitchellh.com/abandoning-rubygems)) but as of v2, Vagrant is only provided as a system package. You
can install two Vagrants (using `gem install` and `apt-get install`), both of
which registering a linux command, and
[confuse](https://github.com/RiotGames/berkshelf/issues/368#issuecomment-13736368)
yourself! 

The `Vagrantfile` here is written for Vagrant v2. To
rollback to Vagrant v1 apply the following to it:
- use `Vagrant.configure("1")` or `Vagrant::Config.run`
- for port forwarding use `config.vm.forwarded\_port, guest: 80, host: 8080`
- `config.vm.customize ["modifyvm", :id, "--memory", "512"]` instead of the
  provider specific block (`config.vm.provider :virtualbox do`) 

#### Chef versions
Chef 11 introduced many backward incompatible features. But Ubuntu 12.04
(precise) comes with an older version of Chef that cannot make sense of many
mainstream cookbooks. Therefore, for now, we are installing a modern version of
Chef using an inline shell provision command.

## Post-Provisioning Drupal 7

#### Port forwarding issue
In a port forwarded setup, Drupal would not realize its own true host port,
since it the global variable `$base_url` is read off of `http_host` which
contains the information before port forwarding. Due to this problem the
variable `http_request_status_fails` should be set to `false` to suppress errors
in status reports.

Notice that in no other setting but this, the error can be avoided and Drupal
should be able to resolve its own FQDN properly. For example,
if you are using a proxy, you can use the
`UseCanonicalName` and `UseCanonicalPhysicalPort` directives in Apache. Even in
the port forwarded setup, with this directive, Apache sets the right
`HTTP_PORT`, but Drupal only looks at `HTTP_HOST` that contains the wrong port.

#### Update status problem
Upon fresh installation, and only sometimes, Drupal shows an
error: "There was a problem checking available updates for Drupal", in the
status report and when trying to access the Modules page. But once you
manually check for updates, the issue is resolved. 

The only way that I have been able to reproduce the error consistently has been
`chown -R www-data:<whatever> modules/update/`. As far as I have checked, checking
for updates manually does not change any of the permissions, but for some
reason, this command (which is run as part of the `drupal-perm.sh` script)
causes this error.

notes:
- I tried removing setgid (`chmod -R g-s`), did not help.
- I tried `chown -R www-data:www-data`, did not help.
- I tried `chown www-data:www-data`, the problem goes away, but:
- The only directory inside `modules/update/` is `test/`. By running `chown
  www-data:www-data  modules/update/.` and consequently `chown -R
  www-data:www-data modules/update/test`, the Drupal status error goes away,
  although technically it should have had the exact same effect as owning the
  entire directory at once.

#### Note on Linux file permissions 
Permission rules take precedence in order of specifity. For example, assume user
`bob` is in group `smith`, and file `foo` is owned by `bob:smith` with
permissoins `r--,rw-,---`. User `bob` cannot write on the file, despite
the fact that all other members of `smith` have write access to it.

## Testing 

Since Vagrant is the primary testing and debugging tool, there exists a
`Vagrantfile` in the repository that provisions a virtual machine serving Drupal
and runs minitests after provisioning. You should be careful with running
multiple Vagrant machines while testing different things. Vagrant is generally
[not
good](https://groups.google.com/forum/#!msg/vagrant-up/YNcGex2Ffjs/AzTDkxN3078J)
with concurrency; at the very least, you should change your port forwarding
configuration. The better way to run multiple tests is to use Test-Kitchen in
parallel mode (`kitchen test --parallel`).

#### Minitest
Tests are written using the
[minitest-handler](https://github.com/btm/minitest-handler-cookbook) cookbook.
Look at
[this](https://github.com/calavera/minitest-chef-handler/blob/v0.4.0/examples/spec_examples/files/default/tests/minitest/example_test.rb)
for an example of how it works. Once test recipes are written, all that needs to
be done is first, add `minitest-handler` to Berkshelf's dependencies (in the
`Berksfile`), and second, add `recipe[minitest-handler]` to Chef's run list.

Also, keep in mind that the path where test
recipes are looked up has changed in recent versions (refer to their
[README](https://github.com/btm/minitest-handler-cookbook)).
Currently, they are expected to be found at `files/default/test/*_test.rb`

#### Test-Kitchen
Automated testing of different combinations of provisioning and minitest recipes
on multiple platforms is done by
[Test-Kitchen](https://github.com/opscode/test-kitchen).  Currently, this
cookbook is using Test-Kitchen's [Vagrant
driver](https://github.com/portertech/kitchen-vagrant). The only other official
Opscode alternative is [EC2](https://github.com/opscode/kitchen-ec2), but
portertech has written drivers for
[LXC](https://github.com/portertech/kitchen-lxc) and
[Docker](https://github.com/portertech/kitchen-docker).

For a good introduction to Test-Kitchen, look at jtimberman's
[two](http://jtimberman.housepub.org/blog/2013/03/19/anatomy-of-a-test-kitchen-1-dot-0-cookbook-part-1/)
[part](http://jtimberman.housepub.org/blog/2013/03/19/anatomy-of-a-test-kitchen-1-dot-0-cookbook-part-2/)
blog post. 

To test/debug the cookbook with Test-Kitchen, which simply runs the
minitest test cases defined at `files/default/test/*_test.rb`, you first need to
install [Vagrant](http://downloads.vagrantup.com/) (look at note on Vagrant
versions above). The rest is straightforward:

``` bash
git clone https://github.com/amirkdv/chef-deploy-drupal.git
cd chef-deploy-drupal
# install vagrant-berkshelf, kitchen-vagrant:
bundle install
kitchen test
```

#### Travis CI
Right now, [Travis-CI](https://travis-ci.org/) is being used only minimally;
only `foodcritic` and `knife cookbook test` are run against the cookbook. I
tried to setup a simple convergence test using minitest.
[Here](https://gist.github.com/amirkdv/5880307) is the `Rakefile` and
[here](https://gist.github.com/amirkdv/5880656) is the `Gemfile` I used.

The first thing to remember is that Travis workers have (an old version of) Chef
[running](http://about.travis-ci.org/docs/user/ci-environment/#How-VM-images-are-upgraded-and-deployed),
which is used by Travis itself to provision them. So, the `Gemfile` should
specifically ask for a modern version of Chef to be installed (say `11.2.0`)
alongside the original one. 

Fixing that, Chef would get stuck while trying to perform `action :restart` on
`mysql`. Since Travis workers have MySQL running [on
boot](http://about.travis-ci.org/docs/user/database-setup/#MySQL), I tried
running the following as a `before_script` in `.travis.yml`:

``` bash
sudo apt-get purge mysql-client mysql-server mysql-common mysql-server-core
```

This resulted in Chef throwing an error at the same spot.
[Here](https://s3.amazonaws.com/amir-bin/travis-chef-log.txt) is the last
recorded log of the failed attempt to configure a Travis worker using only the
[mysql cookbook](https://github.com/opscode-cookbooks/mysql).

Ideally, at least the "fresh Drupal install" use case (see Scope below)
should be tested on Travis.

#### Alternatives
Take a look at mlafeldt's [skeleton
cookbook](https://github.com/mlafeldt/skeleton-cookbook) for ChefSpec Unit
testing on Travis.

Also, look at [these](http://www.iflowfor8hours.info/2012/11/chef-testing-stratagies-compared/)
[two](http://technology.customink.com/blog/2012/08/03/testing-chef-cookbooks/)
about different strategies for testing Chef cookbooks.

It seems that Jenkins is a popular platform for continuous integration testing
of Chef cookbooks, look at jtimberman's blogpost
[here](http://jtimberman.housepub.org/blog/2013/05/08/test-kitchen-and-jenkins/),
and his [cookbook](https://github.com/jtimberman/kitchen-jenkins-cookbook) for
setting up a Jenkins build environment.

# Workflow and Main Use Cases

## Scope
The use cases for the cookbook should be defined in a broader sense than the
example Vagrant setup. The following are all potential use cases for the
cookbook:

1. The curious: **play** with Drupal with minimal effort and cruft
(`Vagrantfile` + `Berksfile` orgnized in a usable way;
[Vagrant-Drupal](http://github.com/dergachev/vagrant-drupal)).  
1. The developer/designer: **develop** a Drupal project, continuously, in an
environment that is consistent over **time**. This use case has requirements for
being able to perform version control in the VM.
1. The dev-team: **collaborate** on a Drupal project in an environment that is
consistent for all members of the team. This use case has requirements for
**remote** version control.
1. The sysadmin: **configure** a development/production environment to serve
a Drupal site. This requires a bootstrap script to configure a server from
scratch as such:

``` bash
apt-get install ruby1.9.3 libxml2-dev libxslt-dev git
gem install chef berkshelf
# load Berksfile, dna.json, and solo.rb somehow ...
berks install -p /tmp/cookbooks
cd tmp
chef-solo -c solo.rb -j dna.json
```

The differences between the requirements of the use cases above should be
understood, and the use cases to be supported should be identified before
reasonable test cases can be defined.

In any case, one major question must be resolved: 
  Is the cookbook expected to deduce on its own whether it should load an existing
  site or create a new one? And if yes (the alternative being that this switch is
  controlled via an attribute) what should happen if there is any discrepancy
  between the code base (specifically `settings.php`), the sql dump, the
  attributes provided to the cookbook, and the potentially non-trivial state of
  the Chef node (after the first round of provisioning).

## Current Thoughts on Scope
#### Use Case Attributes
One obvious solution to the complication described above is to use Chef
attributes to decide between the different use cases (fresh install, load
existing site, bootstrap existing codebase). These attributes can be set in
`dna.json`, and in the virtualization case can be passed to Chef using
environment variables (see [Reset-Functionality][] below):

```bash
case=[fresh,reset,load] vagrant [up,provision]
```

#### Recipe Decomposition
This might be a better recipe decomposition of the existing workflow:

1. `deploy-drupal::lamp_stack`
1. `deploy-drupal::pear_dependencies`
1. `deploy-drupal::load_existing_site`
1. `deploy-drupal::create_new_site`
1. `deploy-drupal::default` (minimal)

#### Drush custom command(s)
One good solution for implementing the ability to fully understand the state of
a Drupal site (sys-admin-vise) and spot (and deal with) discrepancies mentioned
above is native PHP code as a Drush command. 
[Here](https://gist.github.com/amirkdv/5880641) is a Ruby script
that parses the output of `drush status`, which in the latest version (6.x)
accepts a significantly wider array of options.

The current release of Drush (test on earlier stable versions?) has the
following issue in `drush status`. If **all** the following conditions hold:

1. credentials exist in `settings.php`,
2. database with specified name exists,
3. specified user has access to the database,
4. specified database is empty

then drush throws an exception (not if any of the conditions above does not hold).

#### Security
For now, user management is considered outside the scope of this cookbook. The
only user/group management that happens in the cookbook is the ownership of the
deployed project root by a group defined in the attribute `dev_group_name` which
defaults to `root` (and in the Vagrant use case can easily be replaced with
`vagrant`). If the provided group name does not exist, it will not be created,
nor will the cookbook add any users to this group.

If such measures are to be implemented in the cookbook, a good place to start
would be the [sudo
cookbook](https://github.com/opscode-cookbooks/sudo) for configuring and
managing sudoers.

Also, none of the passwordless MySQL user accounts will be
[secured](http://dev.mysql.com/doc/refman/5.0/en/default-privileges.html) by the
cookbook. If this were to be included at some point in the cookbook, the easiest
way would be to run the following:

``` sql
UPDATE mysql.user
  SET password = PASSWORD ('newpwd')
  WHERE password='';
```

Note that this would disallow an empty root password which might be desirable.
An alternative would be to remove all MySQL users that are defined using
wildcards (`''` usernames and/or `%` hosts).


#### Reset functionality
Currently, reset functionality is provided through setting an environment
varible in the Vagrant run like this `reset=true vagrant [up,provision]`
If the solo-provisioner script is to be used, Right now the `Vagrantfile` does two things regarding chef attributes:

``` ruby
reset = ENV["reset"].nil? ? "" : ENV["reset"]
chef.json.merge!({
    . . .
    "deploy-drupal" => { 
      "reset" => reset
      . . .
    }
    . . .
}) 
```

The issue is that if the second part is run as above, the configuration in
`dna.json` will be ignored since the following block would be added to the end
of `dna.json`:

``` ruby
"deploy-drupal" : { 
  "destroy_existing" : "true" 
}
```

and Chef will ignore the initial `"deploy-drupal"` block.  If it is run using
`merge` (instead of `merge!`) it will not merge at all (no `destroy_existing`
inside `dna.json` in VM).


## Changes in password attributes:
1. **MySQL** password (for the Drupal MySQL user):

[Apparently](http://dev.mysql.com/doc/refman/5.1/en/grant.html) as far as MySQL
is concerned, all we need to do is to get read of our `CREATE USER` statements
and only use this:

``` sql
GRANT ALL ON <drupal_db_name>.* TO '<user>'@'<host>' IDENTIFIED BY '<password>'
```

and this will ensure the following:
> When the IDENTIFIED BY clause is present and you have global grant
> privileges, the password becomes the new password for the account, even if the
> account exists and already has a password. With no IDENTIFIED BY clause, the
> account password remains unchanged.

and:

> If the `NO_AUTO_CREATE_USER` SQL mode is not enabled and the account named in a
> `GRANT` statement does not exist in the `mysql.user` table, `GRANT` creates it.

But the trouble is that once the Drupal site is bootstrapped, if the provisioner
changes the database credentials, `drush status` would show the connection
failure and
the cookbook would fire up `drush site-install` and that would drop the entire
database! A more crafty workaround has to be developed for password resetting.
