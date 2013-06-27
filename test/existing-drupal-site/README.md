# test/existing-drupal-site

Installs deploy_drupal::lamp_stack, then uses "drush qd" to creates drupal site & SQL dump in /tmp/quick-drupal.
Afterwards it uses deploy_drupal::default to install the existing site to /var/shared/sites/existing-drupal-sites.
Finally it checks to make sure that apache is serving this exact site (with title "drupal-from-sql-dump") on port 80.

To perform the test, run the following:

```
librarian-chef install  
vagrant up              
```
