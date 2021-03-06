# this sql script will auto run when the mysql container starts and the $DATA_PATH_HOST/mysql not found.
#
# if your $DATA_PATH_HOST/mysql exists and you do not want to delete it, you can run by manual execution:
#
#     docker-compose exec mysql bash
#     mysql -u root -p < /docker-entrypoint-initdb.d/createdb.sql
#

CREATE DATABASE IF NOT EXISTS `opendialog` COLLATE 'utf8_general_ci' ;
GRANT ALL ON `opendialog`.* TO 'opendialog'@'%' ;


FLUSH PRIVILEGES ;
