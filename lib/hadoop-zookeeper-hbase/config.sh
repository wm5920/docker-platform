#!/bin/bash
#本来都写在Dockerfile中的，但是构建的时候提示max depth exceeded，把配置放到config.sh中去 
coresite=/home/hadoop-2.7.3/etc/hadoop/core-site.xml
hdfssite=/home/hadoop-2.7.3/etc/hadoop/hdfs-site.xml
mapredsite=/home/hadoop-2.7.3/etc/hadoop/mapred-site.xml
yarnsite=/home/hadoop-2.7.3/etc/hadoop/yarn-site.xml
hbasesite=/home/hbase-1.2.3/conf/hbase-site.xml

echo "修改$coresite配置"
sed -i "s/<\/configuration>//g" $coresite
echo '<property>'>>$coresite
echo '	<name>hadoop.tmp.dir</name>'>>$coresite
echo '	<value>file:/home/hadoop-2.7.3/tmp</value>'>>$coresite
echo '	<description>A base for other temporary directories.</description>'>>$coresite
echo '</property>'>>$coresite
echo '<property>'>>$coresite
echo '	<name>fs.defaultFS</name>'>>$coresite
echo '	<value>hdfs://master:9000</value>'>>$coresite
echo '</property>'>>$coresite
echo '<property>'>>$coresite
echo '	<name>io.file.buffer.size</name>'>>$coresite
echo '	<value>131702</value>'>>$coresite
echo '</property>'>>$coresite
echo '</configuration>'>>$coresite


echo "修改$hdfssite配置"
sed -i "s/<\/configuration>//g" $hdfssite
echo '<property>'>>$hdfssite
echo '	<name>dfs.replication</name>'>>$hdfssite
echo '	<value>2</value>'>>$hdfssite
echo '</property>'>>$hdfssite
echo '<property>'>>$hdfssite
echo '	<name>dfs.namenode.name.dir</name>'>>$hdfssite
echo '	<value>file:/home/hadoop-2.7.3/dfs/name</value>'>>$hdfssite
echo '</property>'>>$hdfssite
echo '<property>'>>$hdfssite
echo '	<name>dfs.datanode.data.dir</name>'>>$hdfssite
echo '	<value>file:/home/hadoop-2.7.3/dfs/data</value>'>>$hdfssite
echo '</property>'>>$hdfssite
echo '<property>'>>$hdfssite
echo '	<name>dfs.namenode.secondary.http-address</name>'>>$hdfssite
echo "将secondary节点默认设为node1"
echo '	<value>node1:9001</value>'>>$hdfssite
echo '</property>'>>$hdfssite
echo '<property>'>>$hdfssite
echo '	<name>dfs.webhdfs.enabled</name>'>>$hdfssite
echo '	<value>true</value>'>>$hdfssite
echo '</property>'>>$hdfssite
echo '</configuration>'>>$hdfssite

echo "修改$mapredsite配置"
cp $mapredsite.template $mapredsite
sed -i "s/<\/configuration>//g" $mapredsite
echo '<property>'>>$mapredsite
echo '    <name>mapreduce.framework.name</name>'>>$mapredsite
echo '    <value>yarn</value>'>>$mapredsite
echo '</property>'>>$mapredsite
echo '<property>'>>$mapredsite
echo '    <name>mapreduce.jobhistroy.address</name>'>>$mapredsite
echo '    <value>master:10020</value>'>>$mapredsite
echo '</property>'>>$mapredsite
echo '<property>'>>$mapredsite
echo '    <name>mapreduce.jobhistory.webapp.address</name>'>>$mapredsite
echo '    <value>master:19888</value>'>>$mapredsite
echo '</property>'>>$mapredsite
echo '</configuration>'>>$mapredsite

echo "修改$yarnsite配置"
sed -i "s/<\/configuration>//g" $yarnsite
echo '<property>'>>$yarnsite
echo '        <name>yarn.nodemanager.aux-services</name>'>>$yarnsite
echo '        <value>mapreduce_shuffle</value>'>>$yarnsite
echo '    </property>'>>$yarnsite
echo '    <property>'>>$yarnsite
echo '        <name>yarn.nodemanager.auxservices.mapreduce.shuffle.class</name>'>>$yarnsite
echo '        <value>org.apache.hadoop.mapred.ShuffleHandler</value>'>>$yarnsite
echo '    </property>'>>$yarnsite
echo '    <property>'>>$yarnsite
echo '        <name>yarn.resourcemanager.address</name>'>>$yarnsite
echo '        <value>master:8032</value>'>>$yarnsite
echo '    </property>'>>$yarnsite
echo '    <property>'>>$yarnsite
echo '        <name>yarn.resourcemanager.scheduler.address</name>'>>$yarnsite
echo '        <value>master:8030</value>'>>$yarnsite
echo '    </property>'>>$yarnsite
echo '    <property>'>>$yarnsite
echo '        <name>yarn.resourcemanager.resource-tracker.address</name>'>>$yarnsite
echo '        <value>master:8031</value>'>>$yarnsite
echo '    </property>'>>$yarnsite
echo '    <property>'>>$yarnsite
echo '        <name>yarn.resourcemanager.admin.address</name>'>>$yarnsite
echo '        <value>master:8033</value>'>>$yarnsite
echo '    </property>'>>$yarnsite
echo '    <property>'>>$yarnsite
echo '        <name>yarn.resourcemanager.webapp.address</name>'>>$yarnsite
echo '        <value>master:8088</value>'>>$yarnsite
echo '    </property>'>>$yarnsite
echo '    <property>'>>$yarnsite
echo '        <name>yarn.nodemanager.resource.memory-mb</name>'>>$yarnsite
echo '        <value>768</value>'>>$yarnsite
echo '	</property>'>>$yarnsite
echo '</configuration>'>>$yarnsite




echo "创建slaves"
touch /home/hadoop-2.7.3/etc/hadoop/slaves 
echo "node1">>/home/hadoop-2.7.3/etc/hadoop/slaves 
echo "node2">>/home/hadoop-2.7.3/etc/hadoop/slaves 



echo "修改hadoop ssh端口为2022"
echo 'export HADOOP_SSH_OPTS="-p 2022"'>>/home/hadoop-2.7.3/etc/hadoop/hadoop-env.sh
echo "设置hadoop的jdk环境，必须的哦"
sed -i 's/${JAVA_HOME}/\/home\/jdk\/jdk1.8.0_111/g' /home/hadoop-2.7.3/etc/hadoop/hadoop-env.sh




echo "创建/home/zookeeper-3.4.6/conf/zoo.cfg"
cp /home/zookeeper-3.4.6/conf/zoo_sample.cfg /home/zookeeper-3.4.6/conf/zoo.cfg
sed -i "s/\/tmp\/zookeeper/\/home\/zookeeper-3.4.6\/data/g" /home/zookeeper-3.4.6/conf/zoo.cfg
echo "dataLogDir=/home/zookeeper-3.4.6/log">>/home/zookeeper-3.4.6/conf/zoo.cfg
echo "server.1=master:2888:3888">>/home/zookeeper-3.4.6/conf/zoo.cfg
echo "server.2=node1:2888:3888">>/home/zookeeper-3.4.6/conf/zoo.cfg
echo "server.3=node2:2888:3888">>/home/zookeeper-3.4.6/conf/zoo.cfg
mkdir /home/zookeeper-3.4.6/log
mkdir /home/zookeeper-3.4.6/data



echo "修改$hbasesite配置"
sed -i "s/<\/configuration>//g" $hbasesite
echo '	<property>'>>$hbasesite
echo '        <name>hbase.zookeeper.quorum</name>'>>$hbasesite
echo '        <value>master,node1,node2</value>'>>$hbasesite
echo '        <description>quorum</description>'>>$hbasesite
echo '    </property>'>>$hbasesite
echo '    <property>'>>$hbasesite
echo '        <name>hbase.zookeeper.property.dataDir</name>'>>$hbasesite
echo '        <value>/home/hbase-1.2.3/zkdata</value>'>>$hbasesite
echo '        <description>dataDir</description>'>>$hbasesite
echo '    </property>'>>$hbasesite
echo '    <property>'>>$hbasesite
echo '        <name>hbase.rootdir</name>'>>$hbasesite
echo '        <value>hdfs://master:9000/hbase</value>'>>$hbasesite
echo '        <description>rootdir</description>'>>$hbasesite
echo '    </property>'>>$hbasesite
echo '    <property>'>>$hbasesite
echo '        <name>hbase.cluster.distributed</name>'>>$hbasesite
echo '        <value>true</value>'>>$hbasesite
echo '        <description>distributed</description>'>>$hbasesite
echo '    </property>'>>$hbasesite
echo '     <property>'>>$hbasesite
echo '        <name>hbase.master.info.port</name>'>>$hbasesite
echo '        <value>60010</value>'>>$hbasesite
echo '        <description>master.port</description>'>>$hbasesite
echo '    </property>'>>$hbasesite
echo '	<property>'>>$hbasesite
echo '	  <name>hbase.regionserver.wal.codec</name>'>>$hbasesite
echo '	  <value>org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec</value>'>>$hbasesite
echo '	</property>'>>$hbasesite
echo '	<property>'>>$hbasesite
echo '	  <name>hbase.region.server.rpc.scheduler.factory.class</name>'>>$hbasesite
echo '	  <value>org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory</value>'>>$hbasesite
echo '	  <description>Factory to create the Phoenix RPC Scheduler that uses separate queues for index and metadata updates</description>'>>$hbasesite
echo '	</property>'>>$hbasesite
echo '	<property>'>>$hbasesite
echo '	  <name>hbase.rpc.controllerfactory.class</name>'>>$hbasesite
echo '	  <value>org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory</value>'>>$hbasesite
echo '	  <description>Factory to create the Phoenix RPC Scheduler that uses separate queues for index and metadata updates</description>'>>$hbasesite
echo '	</property>'>>$hbasesite
echo '</configuration>'>>$hbasesite

echo "创建regionservers"
touch /home/hbase-1.2.3/conf/regionservers
echo "node1">>/home/hbase-1.2.3/conf/regionservers
echo "node2">>/home/hbase-1.2.3/conf/regionservers

echo "修改hbase环境 /home/hbase-1.2.3/conf/hbase-env.sh"
sed -i 's/export HBASE_MASTER_OPTS/#export HBASE_MASTER_OPTS/g' /home/hbase-1.2.3/conf/hbase-env.sh
sed -i 's/export HBASE_REGIONSERVER_OPTS/#export HBASE_REGIONSERVER_OPTS/g' /home/hbase-1.2.3/conf/hbase-env.sh
echo "export HBASE_MANAGES_ZK=false">>/home/hbase-1.2.3/conf/hbase-env.sh
echo 'export HBASE_SSH_OPTS="-p 2022"'>>/home/hbase-1.2.3/conf/hbase-env.sh
echo "export JAVA_HOME=/home/jdk/jdk1.8.0_111">>/home/hbase-1.2.3/conf/hbase-env.sh

