# docker-mysql

# How to Use the MySQL Images

## Start a MySQL Server Instance

Start a MySQL instance as follows (but make sure you also read the sections Secure Container Startup and Where to Store Data below):
`docker run --name my-container-name -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql/mysql-server:tag`

## Connect to MySQL from an Application in Another Docker Container

This image exposes the standard MySQL port (3306)
`docker run --name app-container-name --link my-container-name:mysql -d app-that-uses-mysql`

## Connect to MySQL from the MySQL Command Line Client

The following command starts a new process inside an existing MySQL container instance and runs the mysql command line client against your original MySQL server, allowing you to execute SQL statements against your database:
`docker exec -it my-container-name mysql -uroot -p`

# Environment Variables

## MYSQL_ROOT_PASSWORD
## MYSQL_RANDOM_ROOT_PASSWORD
> When this variable is set to yes, a random password for the server's root user will be generated. The password will be printed to stdout in the container, and it can be obtained by using the command docker logs my-container-name

## MYSQL_ONETIME_PASSWORD
> This variable is optional. When set to yes, the root user's password will be set as expired, and must be changed before MySQL can be used normally. This is only supported by MySQL 5.6 or newer.

## MYSQL_DATABASE
> This variable is optional. It allows you to specify the name of a database to be created on image startup. If a user/password was supplied (see below) then that user will be granted superuser access (corresponding to GRANT ALL) to this database.

## MYSQL_USER, MYSQL_PASSWORD
> These variables are optional, used in conjunction to create a new user and set that user's password. This user will be granted superuser permissions (see above) for the database specified by the MYSQL_DATABASE variable. Both variables are required for a user to be created.

## MYSQL_ALLOW_EMPTY_PASSWORD
> Set to yes to allow the container to be started with a blank password for the root user. NOTE: Setting this variable to yes is not recommended

## MYSQL_ROOT_HOST
> By default, MySQL creates the 'root'@'localhost' account. This account can only be connected to from inside the container, requiring the use of the docker exec command as noted under Connect to MySQL from the MySQL Command Line Client. To allow connections from other hosts, set this environment variable. As an example, the value "172.17.0.1", which is the default Docker gateway IP, will allow connections from the Docker host machine.

# Secure Container Startup

## use MYSQL_RANDOM_ROOT_PASSWORD
```
docker run --name my-container-name -e MYSQL_RANDOM_ROOT_PASSWORD=yes -e MYSQL_ONETIME_PASSWORD=yes -d mysql/mysql-server:tag
docker logs my-container-name
```
Look for the "GENERATED ROOT PASSWORD" line in the output.

## use MYSQL_ONETIME_PASSWORD
If you also set the MYSQL_ONETIME_PASSWORD variable, you must now start a bash shell inside the container in order to set a new root password:
```
docker exec -it my-container-name bash
mysql -u root -p
ALTER USER 'root'@'localhost' IDENTIFIED BY 'my-secret-pw';
```

## use MYSQL_ROOT_PASSWORD
An alternative is to use MYSQL_ROOT_PASSWORD, but set it to point to a file that contains the password. This provides better security than having the password on the command line and is easier to use in automated processes than the random password:
```
docker run --name my-container-name -e MYSQL_ROOT_PASSWORD=/tmp/password.txt -v mypasswordfile:/tmp/password.txt -e MYSQL_ONETIME_PASSWORD=yes -d mysql/mysql-server:tag
```
# Where to Store Data
1. Let Docker manage the storage of your database data by writing the database files to disk on the host system using its own internal volume management. This is the default and is easy and fairly transparent to the user.
2. Create a data directory on the host system (outside the container) and mount this to a directory visible from inside the container.

We will simply show the basic procedure here for the latter option above:
1. Create a data directory on a suitable volume on your host system, e.g. /my/own/datadir.
2. Start your MySQL container like this:
```
docker run --name my-container-name -v /my/own/datadir:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql/mysql-server:tag
```
> The -v /my/own/datadir:/var/lib/mysql part of the command mounts the /my/own/datadir directory from the underlying host system as /var/lib/mysql inside the container, where MySQL by default will write its data files.

Note that users on systems with SELinux enabled may experience problems with this. The current workaround is to assign the relevant SELinux policy type to the new data directory so that the container will be allowed to access it:
```
chcon -Rt svirt_sandbox_file_t /my/own/datadir
```

# Port forwarding
If you start the container as follows, you can connect to the database by connecting your client to a port on the host machine, in this example port 6603:
```
docker run --name my-container-name -p 6603:3306 -d mysql/mysql-server
```
# Passing options to the server
You can pass arbitrary command line options to the MySQL server by appending them to the run command:
```
docker run --name my-container-name -d mysql/mysql-server --option1=value --option2=value
```

In this case, the values of option1 and option2 will be passed directly to the server when it is started. The following command will for instance start your container with UTF-8 as the default setting for character set and collation for all databases in MySQL:
```
docker run --name my-container-name -d mysql/mysql-server --character-set-server=utf8 --collation-server=utf8_general_ci
```

# Using a Custom MySQL Config File

The MySQL startup configuration in these Docker images is specified in the file /etc/my.cnf. If you want to customize this configuration for your own purposes, you can create your alternative configuration file in a directory on the host machine and then mount this file in the appropriate location inside the MySQL container, effectively replacing the standard configuration file.

If you want to base your changes on the standard configuration file, start your MySQL container in the standard way described above, then do:
```
docker exec -it my-container-name cat /etc/my.cnf > /my/custom/config-file
```
Make your changes and then start a new MySQL container like this:
```
docker run --name my-new-container-name -v /my/custom/config-file:/etc/my.cnf -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql/mysql-server:tag
```
Note that users on systems where SELinux is enabled may experience problems with this. The current workaround is to assign the relevant SELinux policy type to your new config file so that the container will be allowed to mount it:
```
chcon -Rt svirt_sandbox_file_t /my/custom/config-file
```
