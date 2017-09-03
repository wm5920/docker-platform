#!/bin/bash
mysql -uroot -proot<<-EOF
create database web default charset utf8 COLLATE utf8_general_ci;
show databases;
EOF
mysql -uroot -proot web</web.sql