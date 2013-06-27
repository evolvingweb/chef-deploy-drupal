Deploy Drupal Cookbook
================

Installs and configures a Drupal 7 site running on MySQL and Apache. The cookbook
supports two main use cases:

- You **have** a Drupal site and want to deploy it over a virtual server,
  potentially the setup with Vagrant [here](../../). 

- You want to configure a server, virtual or not, to run a fresh installation of
  Drupal.

Description
----------- 
The cookbook first checks out the following from the Vagrant root directory 
(the directory containing your `Vagrantfile`):

1. A Drupal site in `./public`
2. A database dump at `./db/fga.sql.gz`, and 
3. post-installation SQL script at `./db/fga-sql-post-load.sh`.

If you have a bootstrapped drupal site in the `./public` directory and no
database dump, the cookbook will try to initialize the database with the
credentials provided in `settings.php`. These credentials must be identically
reflected in the cookbook attributes, otherwise the cookbook will not proceed
(**it does now, but it should not**).

If the cookbook fails to build a site with the provided resources, it will
download a fresh stable release of Drupal 7 from [drupal.org](http://drupal.org)
and configures MySQL and Apache according to your attributes (described below).

Recipes
----------- 

- `deploy\_drupal::lamp\_stack`: installs infrastructure packages to support
  Apache, MySQL, PHP, and Drush. 
- `deploy\_drupal::pear\_dependencies`: installs PEAR, PECL, and other PHP
  enhancement packages.
- `deploy\_drupal::default`: is the main recipe that loads and installs Drupal
  and configures MySQL and Apache to serve the site.

Attributes
----------- 
This cookbook defines the following default attributes under
`node['default']['deploy_drupal']`:

<table> <tr> <th> Attribute </th> <th> Default value </th> <th> Notes </th>
</tr> <tr> <td> codebase_source_path </td> <td>  </td> <td> required attribute,
absolute path to drupal folder containing index.php and settings.php </td> </tr>
<tr> <td> site_name </td> <td> cooked.drupal </td> <td> vhost server name </td>
</tr> <tr> <td> deploy_directory </td> <td>
'/var/shared/sites/cooked.drupal/site' </td> <td> can be same as
codebase_source_path </td> </tr> <tr> <td> apache_port</td> <td>  80 </td> <td>
should be consistent with  node['apache']['listen_ports'] </td> </tr> <tr> <td>
apache_user </td> <td>  www-data </td> <td> user owning drupal codebase files
</td> </tr> <tr> <td> apache_group </td> <td>  www-data </td> <td> </td> </tr>
<tr> <td> sql_load_file </td> <td>  </td> <td> absolute path to drupal SQL dump
(can be .gz) </td> </tr> <tr> <td> sql_post_load_script </td> <td>  </td> <td>
absolute path to bash script to run after loading SQL dump </td> </tr> </table>

TODO ====

- Support multi-site Drupal
- Build deploy\_drupal::cron, see:
  - https://github.com/mdxp/drupal-cookbook/blob/master/recipes/cron.rb
  - http://drupal.org/node/23714
