#!/bin/bash
for args in $@
do
    if [ $args = "start-hadoop" ] ; then
        $HADOOP_HOME/sbin/start-dfs.sh
    elif [ $args = "start-hbase" ] ; then
        $HBASE_HOME/bin/start-hbase.sh
    elif [ $args = "init-namenode" ] ; then
        echo "start.sh hadoop-namenode-format"
        rm -rf $HADOOP_HOME/dfs/*
        $HADOOP_HOME/bin/hadoop namenode -format
    elif [ $args = "init-datanode" ] ; then
        echo "start.sh init-datanode"
        rm -rf $HADOOP_HOME/dfs/*
    elif [ $args = "master" ] ; then
        echo "start.sh zookeeper 1"
        echo "1">$ZOOKEEPER_HOME/data/myid
        $ZOOKEEPER_HOME/bin/zkServer.sh start
    elif [ $args = "node1" ] ; then
        echo "start.sh zookeeper 2"
        echo "2">$ZOOKEEPER_HOME/data/myid
        $ZOOKEEPER_HOME/bin/zkServer.sh start
    elif [ $args = "node2" ] ; then
        echo "start.sh zookeeper 3"
        echo "3">$ZOOKEEPER_HOME/data/myid
        $ZOOKEEPER_HOME/bin/zkServer.sh start
    fi
done