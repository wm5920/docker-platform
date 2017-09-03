#!/bin/bash
/home/apache-phoenix-4.9.0-HBase-1.2-bin/bin/sqlline.py localhost<<-EOF
create table if not exists "tb_his_fun"(
"funpk" varchar(50) not null primary key,
"fundata"."data_tstamp" varchar(15),
"fundata"."data_value" varchar(32))immutable_rows=true;

create index "idx_his_fun" on "tb_his_fun"("fundata"."data_tstamp") include("fundata"."data_value");

EOF