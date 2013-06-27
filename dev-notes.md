## Berkshelf
Berkshelf is similar to Librarian-Chef, it uses the contents of a
`Berksfile` (as in `Cheffile` for Librarian-Chef) to load all the cookbooks
identified in the file, as well as all their respective dependencies. But
on top of this, it replaces many portions of Knife, and acts like a
package manager for chef cookbooks. For the docs, look at Berkshelf's
[website](http://berkshelf.com/) for more information.

#### The Berksfile
`[bundle exec] berks install` depends on follows the directives in your `Berksfile` to load
cookbooks (from community API, local system, or git repo). You can also groups
cookbooks together and use this grouping at installation time
(when you perform `berks install`), to exclude or include certain
cookbooks. For example, you can run `[bundle exec] berks install --without
<group-name>`, or other options like `--only`.

You can use the `site` directive in your `Berksfile` to indicate a community
site API to be used by Berkshelf. For using the Opscode's newest community API
you can simply use `:opscode` (instead of
`http://cookbooks.opscode.com/api/v1/cookbooks`). Individual cookbooks can be
loaded from other sources (local, git repo) by the `:path` and `:git` options.

#### Berkshelf Workflow

Berks, as opposed to Librarian-Chef, maintains some sort of state of its own by
installing cookbooks to **its** directory (stored in `BERKSHELF_PATH`, by
default `~/.berkshelf/`). All the
cookbooks that are installed in this way can be catalogued using `berks shelf
list`. Although apparently you can get `berks install` to put the cookbooks in a
custom folder (relative to the directory where install is invoked). In the
latter case, Berkshelf will leave a copy of all cookbooks it installs in the
path you specify, **in addition** to installing them, for further reuse, in its
directory.

Furthermore, the customary way of using Berkshelf is to allow it to install
dependencies on the node as needed. So you provide the node with all *your*
cookbooks and use Berkshelf on the node to load all external dependencies
before provisioning with Chef.

If you wish place your Berksfile in the root of a cookbook, then you can use the
keyword `metdata` in your `Berksfile` to let Berkshelf know that you want it to 
go through the dependencies indicated in the `metadata.rb` file of your cookbook
and load all its dependencies as well. This way, you do not have to indicate the
cookbook within which you have placed your `Berksfile` in your `cookbook`
directives.

#### Berkshelf and Vagrant
Berkshelf works easily with Vagrant through a plugin (`vagrant plugin install
vagrant-berkshelf`). If you want Vagrant to actually use this plugin you should
indicate so in the `Vagrantfile` by adding `config.berkshelf.enabled = true` to
your `Vagrant.configure("2")` block.
Once you have done that, the plugin would
allow vagrant to access Berkshelf's cookbook directory without the `Vagrantfile`
having to contain a `chef.cookbooks_path` directive (this attribute is, in fact,
hijacked by the Vagrant-Berkshelf plugin). All the cookbooks that Berkshelf has
installed (in `~/.berkshelf/`) can be used, and any non-installed cookbooks
indicated in the `Berksfile` will be downloaded and available, as usual, to the VM
at `/tmp/vagrant-chef-1/chef-solo-1/cookbooks/`.

Note that for Vagrant, Berkshelf, and Chef to be able to load up a configured
virtual machine the only configuration files you need is a `Berksfile` and a
`Vagrantfile`. Within your `Berksfile` you can indicate all the cookbooks you
want Chef to use from community API, github, or local filesystem.

## Post-Provisioning Drupal issues

## Drupal's issues with port forwarding
In a port forwarded setup, Drupal would not realize its own true host port,
since it the global variable `$base_url` is read off of `http_host` which
contains the information before port forwarding. Due to this problem the
variable `http_request_status_fails` should be set to `false` to suppress errors
in status reports.

Notice that in no other setting but this, the error can be avoided and Drupal
should be able to resolve its own FQDN properly. For example,
if you are using a proxy, since it is an HTTP layer mechanism, you can use the
`UseCanonicalName` in Apache. Even in the port forwarded setup, with this
directive, Apache sets the right `HTTP_PORT`, but Drupal only looks at
`HTTP_HOST` that contains the wrong port.

## Update status problem
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

## Usage
the three use cases: 
- Quick Drupal: `vagrant up`
- Configure dev/prod enviornment: Berkshelf + Chef provisioner
- Extending/Debugging deploy\_drupal: Vagrant + Test-Kitchen (for multiple
  platform testing)

## Changes in password attributes:

1. **MySQL** password (for the Drupal MySQL user):
[Apparently](http://dev.mysql.com/doc/refman/5.1/en/grant.html) as far as MySQL
is concerned, all we need to do is to get read of our `create user` statements
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

2. Drupal **admin** pasword


## Testing 
minitest

## Drupal Permissions 

Permission rules take precedence in order of specifity (Bob is in group G and file x
is owned by Bob:G with permissoins r-- rw- --- Bob cannot write on the file, despite
the fact that all other members of G have write access)

## Reset functionality
Right now the `Vagrantfile` does two things regarding chef attributes:
``` ruby
chef.json = JSON.parse( IO.read("dna.json") )
chef.json.merge!({
    :deploy_drupal => { 
      :destroy_existing => ENV["destroy"]
    }   
}) 
```
The issue is that if the second part is run as above, the configuration in `dna.json` will be ignored since `"deploy_drupal" : { "destroy_existing" : "true" }` will be added to the end of `dna.json` (in VM) and Chef will ignore the initial `"deploy_drupal"` block.
If it is run using `merge` (instead of `merge!`) it will not merge at all (no `destroy_existing` inside `dna.json` in VM)
## Chef 

## Travis

## Rakefile

## drush status
Here is a drush [status
parser](https://gist.github.com/amirkdv/ce7eedf0814f32568922) in Ruby. This
functionality should potentially be moved into a drush module that checks the
Drupal site status in a directory.

The current release of Drush (test on earlier stable versions?) has the
following issue in `drush status`. If **all** the following conditions hold:

1. credentials exist in `settings.php`,
2. database with specified name exists,
3. specified user has access to the database,
4. specified database is empty

then drush throws an exception (not if any of the conditions above does not hold).

## Vagrant versions
Vagrant v1 refers to `v1.0.x` and Vagrant v2 refers to
anything late, i.e `v1.1+`. The `Vagrantfile` here is written for Vagrant v2. To
rollback to Vagrant v1 apply the following:
- use `Vagrant.configure("1")` or `Vagrant::Config.run`
- for port forwarding use `config.vm.forwarded\_port, guest: 80, host: 8080`
- `config.vm.customize ["modifyvm", :id, "--memory", "512"]` instead of the
  provider specific block (`config.vm.provider :virtualbox do`) 

## Chef versions
  Ubuntu 12.04 (precise) comes with a version of Chef that cannot apparently
  make sense of Librarian-Chef's output. Therefore, we do it using an inline
  shell provision command.

## Debugging
Look at https://gist.github.com/3798773 for a trick to speed up package
installation in vagrant.
