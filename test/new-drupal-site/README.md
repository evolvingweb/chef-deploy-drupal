# test/new-drupal-site

Installs deploy_drupal::lamp_stack and deploy_drupal::default. The latter should use "drush dl drupal" and "drush si"
to create a new Drupal site (name cooked.drupal) to /var/shared/sites/existing-drupal-sites.
This test simply checks that the final site is being served by apache at http://localhost:80.

To perform the test, run the following:

```
librarian-chef install  
vagrant up              
```
