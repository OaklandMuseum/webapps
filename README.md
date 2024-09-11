### Webapps being used by omca

The "Django Webapps" run under Apache/WSGI; OMCA currently uses a slightly customized version of
the "standard" CollectionSpace webapps, this repo only contains those customizations, which are applied
"on top of" the standard codebase by the deployment script.

The following directories are found in this repo:
* `blacklight` Ruby on Rails app supporting public portal
* `docs` documentation for Legacy webapps (Django webapp documentation is available through OMCA staff -- it is a PDF that is too big to keep here)
* `etc` various ad hoc and helper code: fix dups, merge authority terms, etc.
* `etl` Solr ETL scripts ("extract-transform-load") for the OMCA Portals (both Django and Blacklight)
* `omca` the customized code and config files for the Django webapps. This directory contains:
  * `apps` customized applications
  * `config` examples of configuration files for the Django Webapps, customized for OMCA
  * `fixtures` text content of various helpers
* `legacy` Legacy Webapps code, customized for OMCA, pre-ubuntu 18 version. For reference only!
  * `bmu` the two Django webapp modules that had to be customized for OMCA. I put them here rather than make an OMCA branch in the 'standard' repo. If further customization is needed, it might be wise to consider making and maintaining such a branch.
  * `cfgs` configuration files for the Legacy Webapps, customized for OMCA
  * `cswa` original CGI webapp code; now deprecated

#### Webapp Installation

* Documented in Google Docs. Consult OMCA staff for access

#### Webapp Maintenance

* The following instructions are quite terse and cover only one of several possible approaches to maintaining this codebase.
* Hopefully, you will not need to change the code much. 
If the bug you find or enhancement you
make is relevant to all users of these webapps, consider forking the `cspace-deployment` repo and issuing a pull
request to contribute your change.
* Otherwise, the update procedure is the same as for any GitHub-based Django project:

1. Fork-and-clone https://github.com/OaklandMuseum/webapps
2. Get the webapps working on your local system (see the instructions in the repo)
3. Repair the code (on `main` or on a branch of your choosing), commit to your fork
4. Make a release candidate using the script provided (this is 'merely' a Git tag):
* Start a new release: `./webapps/make-release.pl blacklight-1.0.1 webapps "" --new`
* Make a(nother) release candidate `-rc2`, etc.: `./webapps/make-release.pl blacklight-1.0.1 webapps ""`
* Make (tag) a release: `./webapps/make-release.pl blacklight-1.0.1 webapps "" --release`
5. For OMCA, the current deployment of the code is from `jblowe` so once you have gotten
your commit merged into this upstream repo, you can:
5. Login to the server (Dev or Prod), 
6. `sudo su - webapps` to 'become' the webaps user
6. Deploy the version you have made: `nohup ~/webapps/deploy-omca-webapps.sh webapps-6.1.3-rc3 > deploy-webapps-2024-08-27.log &`
8. ... follow instructions in Google Docs; the deploy process does restart the webapps
9. `exit`
10. NB: to restart Apache as your own (super)user:
`sudo apachectl graceful`
