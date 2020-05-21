# OpenDialog Local Development

This package helps you get setup for local development using Docker. It is based on the [Laradock](https://laradock.io) project with (most) unnecessary components removed and allows you to spin up OpenDialog using pre-made docker images from Laradock, the standard [Dgraph](https://dgraph.io) images and the OpenDialog source code.

We first walk through setting up the Docker environment and then setting up OpenDialog within that environment. 

## Setup Docker Environments

To deploy OpenDialog using this package run through the following steps:

+ Make sure the environment you are going to be working in (locally or on a VM) has Docker and Git installed

+ Create a directory called `od-app` (or whatever you prefer to call it, ensuring that any references of od-app in the documentation that follows is replaced by the name you chose).


+ Clone the OpenDialog [appication](https://github.com/opendialogai/opendialog) in a directory called `opendialog` (or your own app name) within od-app.

`git clone git@github.com:opendialogai/opendialog.git opendialog`

+ Clone the OpenDialog Deploy package (i.e. this package), in a directory named `opendialog-development-environment`.

`git clone git@github.com:opendialogai/opendialog-dev-environment.git`

+ The folder structure should be (the names of the directories are important, if you change them to match your project name please follow through in all the other parts mentioned in this doc):
    
  ```
     + od-app
     ++ opendialog
     ++ opendialog-development-environment
   ```

+ Create a copy of `opendialog-development-environment/nginx/sites/opendialog.conf.example` in the same directory, and create `opendialog.conf` (or your own app name). This is your new vhost file, that handles nginx config. 
  Make sure the `server_name` is using the URL you want to use locally and that `root` is pointing to the correct directory (the `public` directory of the OpenDialog application cloned from GitHub). If you are not changing any of the defaults no change is required. 
+ Add the server name that you defined in the nginx configuration to /etc/hosts (e.g. `127.0.0.1 opendialog.test` )
+ Copy `env.example` to `.env`.
+ Change the `DATA_PATH_HOST` to `DATA_PATH_HOST=~/.laradock/opendialog/data` - this ensures that each application will have its own data directory so data will not be shared between multiple installations of OpenDialog apps. 
+ Modify COMPOSE_PROJECT_NAME to match `opendialog` (or your own app name) - this ensures that you are using different containers for each OpenDialog application.
+ Set `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` to appropriate values (you will use this when setting up OpenDialog itself as well)
+ If you change the value of `MYSQL_USER`, update the user in `mysql/docker-entrypoint-initdb.d/createdb.sql`

### Starting up the environment

From withing opendialog-development-environment start all the containers with:
    
    `docker-compose up -d`

Please note that if you have another OpenDialog application up and running you may need to stop those containers in order to avoid port clashing.     
    
This will start all containers including `workspace`,  `dgraph ratel`, `dgraph-zero-test` and `dgraph-server-test` which are not needed to just test an application. To run just the required containers, run

    `docker-compose up -d php-fpm mysql nginx dgrah-zero dgrarh-server memcached`

To connect to the workspace container to run scripts use:
`docker-compose exec workspace bash`.

You are now ready to setup OpenDialog itself.

## Setting up OpenDialog

+ Connect to the workspace container as described above and run the following commands to set the application up:

in `/var/www/opendialog`:

* run `composer install`
* run `cp .env.example .env; php artisan key:generate;`
* Edit .env file and configure the app name, URL and DB settings
    * Use the database credentials you defined above.
    * Use 'mysql' for MySQL host
    * Use `dgraph-server` for the DGraph host
* run `php artisan migrate` to setup tables
* run `php artisan user:create` to create a user
* run `bash update-web-chat.sh -iy` to build the webchat widget for interacting with the bot
* run `php artisan webchat:setup` to setup default values for webchat
* run `php artisan conversations:setup` to setup default conversations
* run `yarn install` and `yarn run dev` to setup the admin interface


### Confirm OpenDialog works

To ensure that it is all working visit http://opendialog.test, you should see the OpenDialog welcome screen and be able to login with the user you created. If you visit http://opendialog.test/admin/demo the bot should load in the page and give you the default welcome message.

### Confirm Dgraph works

To ensure that Dgraph is working visit http://opendialog.test:9001/?latest and point it to http://opendialog.test:8080

You should be able to use the console to run queries such as:

``{
  node(func: eq(ei_type,"conversation_template")) {
    uid
    expand(_all_)
  }
}``

## Automated testing

To run automated tests with PHPUnit first ensure that phpunit.xml has the correct information for connecting to Dgraph.

`
<env name="DGRAPH_URL" value="dgraph-server-test"/>
<env name="DGRAPH_PORT" value="8082"/>
`

You can then run `phpunit`

Keep in mind that this uses a separate Dgraph instance so it will not be changing any data that the application itself is using.  

## Setting up xDebug

- Open the .env file, search for `WORKSPACE_INSTALL_XDEBUG` and set it to `true`
- Still in .env, search for `PHP_FPM_INSTALL_XDEBUG` and set that to `true`
- Rebuild the containers with `docker-compose build workspace php-fpm`


## Configuring PHPStorm

The OpenDialog team is primarily on PhpStorm but these instructions should give you a sense of what is required for any similar IDE.

- In Preferences > Languages & Frameworks > PHP next to the CLI Interpreter drop-down click on the three dotted lines to add a new interpreter.
- Click on + and select "From Docker, Vagrant, VM Remote"
- In the "Configure Remote PHP Interpreter pop-up select Docker Compose"
- Then add the Docker Compose configuration file that is in opendialog-development-environment.
- PhpStorm will automatically pick-up the available services, select `workspace` from the drop-down. Confirm to close the pop-up.
- In CLI Interpreters next to "php executable" click the reload phpinfo button. If that is succesfully retrieves the phpinfo you are one step closer.
- Confirm the interpreter and in the following page add path mappings from whatever your local path is to the root of the OpenDialog application to `/var/www/opendialog/`.
- Next go to Preferences > Languages & Frameworks > PHP > Test Frameworks and add 'PHPUnit by Remote Interpreter' and select the `workspace` interpreter.
- Make sure that "Use Composer Autoloader" is selected and add `/var/www/opendialog/vendor/autoload.php` as the path to script.
- Hit Refresh next to the "Path to Script" field. If it correctly identifies the PHPUnit version installed you should be good to go. 

## Local Package Development

The `packages:install` artisan command will checkout and symlink `opendialog-core` and / or `opendialog-webchat` to a `vendor-local` directory.

To install dependencies using it, you can run `artisan packages:install`. You will be asked if you want to use local versions of core and webchat.
If so, you can now use, edit and version control these repositories directly from your `vendor-local` directory.

After doing so, you may need to run `php artisan package:discover` to pick up any new modules.

Note:
Before a final commit for a feature / fix, please be sure to run `composer update` to update the `composer-lock.json` file so that it can be tested and deployed with all composer changes in place

### Reverting

To revert back to the dependencies defined in `composer.json`, run the `artisan packages:install` command again and answer no to installing core and webchat locally.

## Running Code Sniffer
To run code sniffer, run the following command
```./vendor/bin/phpcs --standard=od-cs-ruleset.xml app/ --ignore=*/migrations/*,*/tests/*```

## Git Hooks

To set up the included git pre-commit hook, first make sure the pre-commit script is executable by running

```chmod +x .githooks/pre-commit```

Then configure your local git to use this directory for git hooks by running:

```git config core.hooksPath .githooks/```

Now every commit you make will trigger php codesniffer to run. If there is a problem with the formatting
of the code, the script will echo the output of php codesniffer. If there are no issues, the commit will
go into git.






