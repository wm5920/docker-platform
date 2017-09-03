#!/bin/bash

#全局配置部分
IP="192.168.2.202"
NOW_PATH="$PWD"
LOCAL_JDK="$NOW_PATH/lib/jdk-8u111-linux-x64/jdk1.8.0_111"
DOCKER_DATA="$NOW_PATH/dockerdata"

DOCKER_REG_ADDR=$IP":5000"
ETCD_NAME="master"
ETCD_LISTEN_CLIENT_URLS="http:\/\/0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http:\/\/"$IP":2379"
ETCD_ADVERTISE_CLIENT_URLS_TEST="http://"$IP":2379"
FLANNEL_ETCD_ENDPOINTS="http:\/\/"$IP":2379"
FLANNEL_OPTIONS="-ip-masq=true"
FLANNEL_NETWORK="10.0.0.0/16"

chmod u+x monitor-web/webmonitor.sh
chmod u+x monitor-web/webmonitor
chmod u+x $LOCAL_JDK/bin/*


#第一步，安装docker
installDockerReg(){
	echo "=============开始安装docker============"
	cd $NOW_PATH
	echo "查看docker安装版本"
	docker -v
	yum install docker -y
	
	echo "修改私服地址,添加到/etc/docker/daemon.json"
	cat <<- EOF>/etc/docker/daemon.json
	{
    	"insecure-registries":["$DOCKER_REG_ADDR"]
	}
	EOF
	cat /etc/docker/daemon.json
	echo "设置docker开机服务自启动"
	systemctl enable docker
	systemctl restart docker

	local isOk=$(systemctl status docker|grep '(dead)')
	
	if [ "$isOk" != "" ];then
		echo "docker服务启动异常，退出"
		exit 0
	fi

	echo "启动docker私服"
	docker rm -f registry
	local hasImage=$(docker images|grep 'registry')
	
	if [ "$hasImage" != "" ]
	then
		echo "已经安装registry镜像"
	else
		docker rmi -f registry
		docker load<dockerimage/registry.tar
	fi
	
	docker run -d -p 5000:5000 --restart always --name=registry registry /entrypoint.sh /etc/docker/registry/config.yml
	sleep 2
	echo "url访问现有镜像库"
	curl "$DOCKER_REG_ADDR/v2/_catalog"
	
}

#第二步 安装etcd
installEtcd(){
	echo "=============开始安装etcd============"
	cd $NOW_PATH
	etcdctl -v
	yum install etcd -y
	
	echo "修改/etc/etcd/etcd.conf配置文件"
	sed -i "s/ETCD_NAME=default/ETCD_NAME=$ETCD_NAME/g" /etc/etcd/etcd.conf
	sed -i "s/ETCD_LISTEN_CLIENT_URLS=\"http:\/\/localhost:2379\"/ETCD_LISTEN_CLIENT_URLS=$ETCD_LISTEN_CLIENT_URLS/g" /etc/etcd/etcd.conf
	sed -i "s/ETCD_ADVERTISE_CLIENT_URLS=\"http:\/\/localhost:2379\"/ETCD_ADVERTISE_CLIENT_URLS=$ETCD_ADVERTISE_CLIENT_URLS/g" /etc/etcd/etcd.conf
	echo "启动etcd服务"
	systemctl enable etcd
	systemctl restart etcd
	echo "测试etcd连接"
	sleep 2
	etcdctl -C "$ETCD_ADVERTISE_CLIENT_URLS_TEST" cluster-health
}

#第三步 安装flannel
installFlannel(){
	echo "=============开始安装flannel============"
	cd $NOW_PATH

	yum install flannel -y
	
	echo "修改/etc/sysconfig/flanneld配置文件"
	sed -i "s/FLANNEL_ETCD_ENDPOINTS=\"http:\/\/127.0.0.1:2379\"/FLANNEL_ETCD_ENDPOINTS=$FLANNEL_ETCD_ENDPOINTS/g" /etc/sysconfig/flanneld
	sed -i "s/#FLANNEL_OPTIONS=\"\"/FLANNEL_OPTIONS=\"$FLANNEL_OPTIONS\"/g" /etc/sysconfig/flanneld
	echo "分配flannel网段"
	etcdctl rm /atomic.io/network/config
	etcdctl mk /atomic.io/network/config "{ \"Network\": \"$FLANNEL_NETWORK\" }"
	echo "启动flannel服务"
	systemctl enable flanneld.service
	systemctl restart flanneld.service
	echo "重启docker"
	systemctl restart docker

}

installCentos7SSH(){
	echo "=============开始创建centos7-ssh镜像============"
	cd $NOW_PATH
	if [ "$1" == "" ]
	then
		docker rmi -f $DOCKER_REG_ADDR/centos7-ssh
		cd $NOW_PATH/lib/centos7-ssh/.
		docker build -t "$DOCKER_REG_ADDR/centos7-ssh" . 
	else
		echo "收到指令不安装centos7-ssh镜像"
	fi
	echo "启动centos7-ssh镜像"
	docker rm -f centos7-ssh
	docker run  -d --name=centos7-ssh  -p 2022:2022  $DOCKER_REG_ADDR/centos7-ssh
	
	echo "进入docker容器里进行秘钥生成，暂时不能通过脚本直接创建秘钥"
	echo "进入容器里后，请输入/home/makessh.sh 执行秘钥生成操作"
	
	docker exec -it centos7-ssh bin/bash

	echo "提交修改到镜像文件"
	docker commit centos7-ssh $DOCKER_REG_ADDR/centos7-ssh
	# echo "提交镜像到私服"
	# docker push $DOCKER_REG_ADDR/centos7-ssh
}

function commonHadoop(){
	cd $NOW_PATH
	echo "添加hosts "
	local ip=`docker inspect hadoop-master|grep '"IPAddress": "'|head -1|awk '{print $2}'`
	local ip1=${ip//','/''}
	local ip2=${ip1//'"'/''}
	local masterip=$ip2
	echo "$ip2 master"
	local ip=`docker inspect hadoop-node1|grep '"IPAddress": "'|head -1|awk '{print $2}'`
	local ip1=${ip//','/''}
	local ip2=${ip1//'"'/''}
	local node1ip=$ip2
	echo "$ip2 node1"
	local ip=`docker inspect hadoop-node2|grep '"IPAddress": "'|head -1|awk '{print $2}'`
	local ip1=${ip//','/''}
	local ip2=${ip1//'"'/''}
	local node2ip=$ip2
	echo "$ip2 node2"
	docker exec -it hadoop-master /home/addhosts.sh  $node1ip node1
	docker exec -it hadoop-master /home/addhosts.sh  $node2ip node2
	docker exec -it hadoop-node1 /home/addhosts.sh  $masterip master
	docker exec -it hadoop-node1 /home/addhosts.sh  $node2ip node2
	docker exec -it hadoop-node2 /home/addhosts.sh  $masterip master
	docker exec -it hadoop-node2 /home/addhosts.sh  $node1ip node1

	echo "启动zookeeper" 
	docker exec -it hadoop-master /home/start.sh master
	docker exec -it hadoop-node1 /home/start.sh node1
	docker exec -it hadoop-node2 /home/start.sh node2
	echo "查看zookeeper状态"
	result=$(docker exec -it hadoop-master /home/zookeeper-3.4.6/bin/zkServer.sh status|grep 'Error')
	echo "返回结果$result"
	if [ "$result" != "" ];then
		echo "hadoop-master zookeeper启动异常，退出执行"
		exit 0
	fi
	
	result=$(docker exec -it hadoop-node1 /home/zookeeper-3.4.6/bin/zkServer.sh status|grep 'Error')
	if [ "$result" != "" ];then
		echo "hadoop-node1 zookeeper启动异常，退出执行"
		exit 0
	fi

	result=$(docker exec -it hadoop-node2 /home/zookeeper-3.4.6/bin/zkServer.sh status|grep 'Error')
	if [ "$result" != "" ];then
		echo "hadoop-node2 zookeeper启动异常，退出执行"
		exit 0
	fi


	echo "启动hadoop-hdfs" 

	docker exec -it hadoop-master /home/start.sh start-hadoop
}

#启动hadoop组件
installHadoop(){
	echo "*************主角hadoop镜像上场*************"
	cd $NOW_PATH
	echo "=============配置jdk环境============="
	echo "修改Dockerfile中的镜像ip和jdk地址"
	sed -i "s/DOCKER_REG_ADDR/$DOCKER_REG_ADDR/g" lib/hadoop-zookeeper-hbase/Dockerfile

	local dockername="centos7-ssh-jdk8-hadoop2.7-zookeeper3.4-hbase1.2"
	docker rmi -f $DOCKER_REG_ADDR/$dockername
	docker rm -f hadoop
	cd $NOW_PATH/lib/hadoop-zookeeper-hbase
	docker build -t "$DOCKER_REG_ADDR/$dockername" .
	docker run  --privileged=true --name=hadoop -v $LOCAL_JDK:/home/jdk/jdk1.8.0_111 -d  $DOCKER_REG_ADDR/$dockername
	echo "查看jdk是否安装成功"
	docker exec -it hadoop java -version
	echo "执行hadoop配置脚本config.sh"
	docker exec -it hadoop /home/config.sh
	echo "提交容器镜像"
	docker commit hadoop $DOCKER_REG_ADDR/$dockername
	# echo "提交镜像到私服"
	# docker push $DOCKER_REG_ADDR/$dockername
	echo "初始化本地数据挂载卷"
	rm -rf $DOCKER_DATA/hadoopdata*
	rm -rf $DOCKER_DATA/hbase-*
	mkdir -p $DOCKER_DATA/hadoopdata-master/tmp
	mkdir -p $DOCKER_DATA/hadoopdata-master/dfs
	mkdir -p $DOCKER_DATA/hadoopdata-master/dfs/data
	mkdir -p $DOCKER_DATA/hadoopdata-master/dfs/name
	mkdir -p $DOCKER_DATA/hadoopdata-master/logs

	mkdir -p $DOCKER_DATA/hadoopdata-node1/tmp
	mkdir -p $DOCKER_DATA/hadoopdata-node1/dfs
	mkdir -p $DOCKER_DATA/hadoopdata-node1/dfs/data
	mkdir -p $DOCKER_DATA/hadoopdata-node1/dfs/name
	mkdir -p $DOCKER_DATA/hadoopdata-node1/logs

	mkdir -p $DOCKER_DATA/hadoopdata-node2/tmp
	mkdir -p $DOCKER_DATA/hadoopdata-node2/dfs
	mkdir -p $DOCKER_DATA/hadoopdata-node2/dfs/data
	mkdir -p $DOCKER_DATA/hadoopdata-node2/dfs/name
	mkdir -p $DOCKER_DATA/hadoopdata-node2/logs

	mkdir -p $DOCKER_DATA/hbase-master/zkdata
	mkdir -p $DOCKER_DATA/hbase-node1/zkdata
	mkdir -p $DOCKER_DATA/hbase-node2/zkdata

	echo "启动三个hadoop容器实例"
	docker rm -f hadoop-node1 hadoop-node2 hadoop-master

	docker run   --name=hadoop-node1  --hostname=node1 -d --privileged=true -v $LOCAL_JDK:/home/jdk/jdk1.8.0_111\
	-v $DOCKER_DATA/hadoopdata-node1/tmp:/home/hadoop-2.7.3/tmp \
	-v $DOCKER_DATA/hadoopdata-node1/dfs:/home/hadoop-2.7.3/dfs \
	-v $DOCKER_DATA/hadoopdata-node1/logs:/home/hadoop-2.7.3/logs \
	-v $DOCKER_DATA/hbase-master/zkdata:/home/hbase-1.2.3/zkdata\
	 $DOCKER_REG_ADDR/$dockername 

	docker run   --name=hadoop-node2  --hostname=node2 -d --privileged=true -v $LOCAL_JDK:/home/jdk/jdk1.8.0_111\
	-v $DOCKER_DATA/hadoopdata-node1/tmp:/home/hadoop-2.7.3/tmp \
	-v $DOCKER_DATA/hadoopdata-node2/dfs:/home/hadoop-2.7.3/dfs \
	-v $DOCKER_DATA/hadoopdata-node2/logs:/home/hadoop-2.7.3/logs \
	-v $DOCKER_DATA/hbase-master/zkdata:/home/hbase-1.2.3/zkdata\
	 $DOCKER_REG_ADDR/$dockername 

	docker run  -p 50070:50070 -p 60010:60010 -p 2181:2181 --name=hadoop-master  --hostname=master -d --privileged=true -v $LOCAL_JDK:/home/jdk/jdk1.8.0_111\
	-v $DOCKER_DATA/hadoopdata-master/tmp:/home/hadoop-2.7.3/tmp \
	-v $DOCKER_DATA/hadoopdata-master/dfs:/home/hadoop-2.7.3/dfs \
	-v $DOCKER_DATA/hadoopdata-master/logs:/home/hadoop-2.7.3/logs \
	-v $DOCKER_DATA/hbase-master/zkdata:/home/hbase-1.2.3/zkdata \
	 $DOCKER_REG_ADDR/$dockername 

	 echo "格式化hadoop-namenode "
	docker exec -it hadoop-master /home/start.sh init-namenode

	commonHadoop


	echo "启动hbase "

	#docker exec -it hadoop-master /home/start.sh start-hbase不能成功启动hbase，为啥？
	
	cat <<- EOF
	# 历史数据表
	create table if not exists "tb_his_fun"(
	"funpk" varchar(50) not null primary key,
	"fundata"."data_tstamp" varchar(15),
	"fundata"."data_value" varchar(32))immutable_rows=true;


	#历史表全局覆盖索引
	create index "idx_his_fun" on "tb_his_fun"("fundata"."data_tstamp") include("fundata"."data_value");
		
	EOF
	echo "启动hbase,请输入/home/start.sh start-hbase"
	echo "创建hbase数据表,请输入/home/create.sh"
	docker exec -it hadoop-master /bin/bash

	echo "浏览器页面通过http://$IP:50070 进行访问， dfs live node有值，点开也有datanode数据才算正常"
	echo "浏览器页面通过http://$IP:60010/master-status#baseStats 确认hbase是否正常"

}



function startHadoop(){
	cd $NOW_PATH
	docker stop hadoop-master hadoop-node1 hadoop-node2
	docker start hadoop-master hadoop-node1 hadoop-node2
	commonHadoop
	echo "启动hbase "

	#docker exec -it hadoop-master /home/start.sh start-hbase不能成功启动hbase，为啥？
	echo "启动hbase,请输入/home/start.sh start-hbase,然后exit退出"
	#/home/hbase-1.2.3/bin/
	docker exec -it hadoop-master /bin/bash
	echo "浏览器页面通过http://$IP:50070 进行访问， dfs live node有值，点开也有datanode数据才算正常"
	echo "浏览器页面通过http://$IP:60010/master-status#baseStats 确认hbase是否正常"
}

addHadoopNode(){
	cd $NOW_PATH
	echo "*************添加hadoop节点*************"
	local dockername="centos7-ssh-jdk8-hadoop2.7-zookeeper3.4-hbase1.2"
	local nodename="node3"

	echo "====创建数据挂载文件夹===="
	rm -rf $DOCKER_DATA/hadoopdata*
	rm -rf $DOCKER_DATA/hbase-*
	mkdir -p $DOCKER_DATA/hadoopdata-$nodename/tmp
	mkdir -p $DOCKER_DATA/hadoopdata-$nodename/dfs
	mkdir -p $DOCKER_DATA/hadoopdata-$nodename/dfs/data
	mkdir -p $DOCKER_DATA/hadoopdata-$nodename/dfs/name
	mkdir -p $DOCKER_DATA/hadoopdata-$nodename/logs
	mkdir -p $DOCKER_DATA/hbase-$nodename/zkdata

	echo "====启动容器实例===="
	docker run   --name=hadoop-$nodename  --hostname=$nodename -d --privileged=true -v $LOCAL_JDK:/home/jdk/jdk1.8.0_111\
	-v $DOCKER_DATA/hadoopdata-$nodename/tmp:/home/hadoop-2.7.3/tmp \
	-v $DOCKER_DATA/hadoopdata-$nodename/dfs:/home/hadoop-2.7.3/dfs \
	-v $DOCKER_DATA/hadoopdata-$nodename/logs:/home/hadoop-2.7.3/logs \
	-v $DOCKER_DATA/hbase-$nodename/zkdata:/home/hbase-1.2.3/zkdata\
	 $DOCKER_REG_ADDR/$dockername 

	echo "剩下的按下面步骤执行" 
	cat <<- EOF
	====修改hosts====

	hadoop-master上修改/etc/hosts/
	添加
	10.0.92.2       $nodename
	hadoop-$nodename上修改/etc/hosts/
	添加
	10.0.97.5       master
	10.0.97.3       node1
	10.0.97.4       node2

	====启动hadoop====
	启动datanode
	docker exec -it hadoop-$nodename /home/hadoop-2.7.3/sbin/hadoop-daemon.sh start datanode

	均衡block
	docker exec -it hadoop-$nodename /home/hadoop-2.7.3/sbin/start-balancer.sh  

	====启动hbase====
	docker exec -it hadoop-$nodename vi /home/hbase-1.2.3/conf/regionservers
	添加$nodename

	docker exec -it hadoop-$nodename  bin/bash 
	/home/hbase-1.2.3/bin/hbase-daemon.sh start regionserver  

	EOF
}
removeHadoopNode(){
	cd $NOW_PATH
	echo "*************移除hadoop节点*************"
	local nodename="node3"
	cat <<- EOF
	====master上hbase删除节点====
	docker exec -it hadoop-$nodename bin/bash  
	/home/hbase-1.2.3/bin/graceful_stop.sh $nodename

	====master hdfs删除节点====
	docker exec -it hadoop-master vi /home/hadoop-2.7.3/etc/hadoop/excludes 
	添加
	$nodename

	docker exec -it hadoop-master bin/bash
	vi /home/hadoop-2.7.3/etc/hadoop/hdfs-site.xml 
	添加
	<property>  
	    <name>dfs.hosts.exclude</name>  
	    <value>/home/hadoop-2.7.3/etc/hadoop/excludes</value>  
	</property>  
	 
	====master刷新====
	docker exec -it hadoop-master /home/hadoop-2.7.3/bin/hadoop dfsadmin -refreshNodes
	页面上Decommissioned显示已退役，成功

	EOF
}

installRedis(){
	echo "========创建debian8.7+redis3.2.6镜像========="
	cd $NOW_PATH
	local has=$(docker images|grep 'redis')
	
	if [ "$has" == "" ]
	then
		docker pull hub.c.163.com/library/redis:latest
		docker tag hub.c.163.com/library/redis:latest $DOCKER_REG_ADDR/redis:latest
		# echo "提交镜像到私服"
		# docker push $DOCKER_REG_ADDR/redis
	else
		echo "已经安装了redis"
	fi

	rm -rf $DOCKER_DATA/redisdata
	mkdir $DOCKER_DATA/redisdata/
	docker rm -f myredis
	docker run --name myredis --privileged=true -p 6379:6379 -v $DOCKER_DATA/redisdata/:/data -d $DOCKER_REG_ADDR/redis redis-server --appendonly yes
	echo "docker run --name myredis  -p 6379:6379 -v $DOCKER_DATA/redisdata/:/data -d $DOCKER_REG_ADDR/redis redis-server --appendonly yes"
	echo "查看redis版本"
	docker run -it --link myredis:redis --rm $DOCKER_REG_ADDR/redis redis-cli -h redis -p 6379 --version
	echo "查看系统版本"
	docker exec -it myredis cat /etc/debian_version
	echo "docker启动可以添加-v redis.conf:/usr/local/etc/redis/redis.conf 从而对redis配置进行自定义配置"
}

installMysql(){
	echo "========创建debian8.7+mysql5.7镜像========="
	cd $NOW_PATH
	local has=$(docker images|grep 'mysql')
	
	if [ "$has" == "" ]
	then
		docker pull hub.c.163.com/library/mysql:latest
		docker tag hub.c.163.com/library/mysql:latest $DOCKER_REG_ADDR/mysql:latest
		# echo "提交镜像到私服"
		# docker push $DOCKER_REG_ADDR/mysql
	else
		echo "已经安装了mysql"
	fi

	rm -rf $DOCKER_DATA/mysqldata
	mkdir $DOCKER_DATA/mysqldata
	docker rm -f mysql

	#-v $PWD/lib/mysql/mysql.cnf:/etc/mysql/conf.d/mysql.cnf
	docker run --name mysql --privileged=true -v $DOCKER_DATA/mysqldata:/var/lib/mysql \
	-v $NOW_PATH/lib/mysql/web.sql:/web.sql \
	-v $NOW_PATH/lib/mysql/create.sh:/create.sh \
	-p 3307:3306 -e MYSQL_ROOT_PASSWORD=root -d $DOCKER_REG_ADDR/mysql

	echo "查看mysql版本,如果启动异常有可能是端口占用哦，当前端口3307"
	docker exec -it mysql mysql --version
	echo "docker启动可以添加-v /my/custom:/etc/mysql/conf.d 从而对mysql配置进行自定义配置"
	echo "连接到mysql进行数据导入,执行下面命令，如果出现Error，请再执行一次"
	echo " ./create.sh"
	docker exec -it mysql chmod 777 /create.sh
	docker exec -it mysql bin/bash
}

installDubboadmin(){
	echo "========创建centos7-jdk8-tomcat7-dubboadmin-dubbomonitor镜像========="
	cd $NOW_PATH
	rm -rf lib/tomcat-web/dubbo-admin-2.8.4
	unzip lib/tomcat-web/dubbo-admin-2.8.4.war -d lib/tomcat-web/dubbo-admin-2.8.4
	docker rmi $DOCKER_REG_ADDR/centos7-jdk8-tomcat7-dubboadmin-dubbomonitor
	docker rm -f dubbo

	cd $NOW_PATH/lib/tomcat-web
	sed -i "s/DOCKER_REG_ADDR/$DOCKER_REG_ADDR/g" dubboadmin-monitor-Dockerfile
	sed -i "s/HOST_IP/$IP/g" dubboadmin-monitor-Dockerfile
	docker build -t $DOCKER_REG_ADDR/centos7-jdk8-tomcat7-dubboadmin-dubbomonitor . -f  dubboadmin-monitor-Dockerfile
	docker run --name=dubbo --privileged=true  --net=host -v $LOCAL_JDK:/home/jdk/jdk1.8.0_111 -itd $DOCKER_REG_ADDR/centos7-jdk8-tomcat7-dubboadmin-dubbomonitor /home/dubbo-start.sh
	echo "查看dubbo admin配置"
	docker exec -it dubbo cat /home/tomcat7/webapps/dubbo-admin-2.8.4/WEB-INF/dubbo.properties
	echo ""
	echo "查看monitor配置"
	docker exec -it dubbo cat /home/dubbo-monitor-simple-2.8.4/conf/dubbo.properties
	echo ""
	echo "页面通过http://$IP:8080/访问监控中心"
	echo "页面通过http://$IP:8482/dubbo-admin-2.8.4/访问服务管理中心"

}


#docker的导入导出不能与exit一起，坑
saveDockerCentos7ssh(){
	#添加变量，表示要等待指令执行完成
	echo "=============测试导出的centos7-ssh镜像是否可用============="
	cd $NOW_PATH
	local output=`docker save $DOCKER_REG_ADDR/centos7-ssh>dockerimage/centos7-ssh.tar`

	docker rm -f centos7-ssh
	docker rmi -f $DOCKER_REG_ADDR/centos7-ssh
	output=`docker load<dockerimage/centos7-ssh.tar`
	docker run  -d --name=centos7-ssh  -p 2022:2022  $DOCKER_REG_ADDR/centos7-ssh
	echo "如果成功ssh镜像，则表示可用，然后exit即可"
	docker exec -it centos7-ssh ssh localhost -p 2022
	echo "发布centos7-ssh镜像"
	docker push $DOCKER_REG_ADDR/centos7-ssh
}

startMonitorWeb(){
	cd $NOW_PATH
	cd $NOW_PATH/monitor-web
	ps -ef | grep webmonitor | awk '{ print $2 }' |  xargs kill -9
	nohup ./webmonitor>log &
}


clearAll(){
	docker rm -f $(docker ps -a -q)
	docker rmi -f $(docker images -q -a)
	cd $NOW_PATH
	yum remove docker -y
	yum remove etcd -y
	yum remove flannel -y
}
initRegistry(){
	cat <<- EOF>/etc/docker/daemon.json
	{
	    "insecure-registries":["$DOCKER_REG_ADDR"]
	}
	EOF
	systemctl restart docker
}
#常用指令
help(){
	
	cat <<- EOF
	+++++++++++++++++++帮助++++++++++++++++++
	docker -v
	卸载docker/etcd/flannel
	yum remove docker etcd flannel
	后台启动以centos镜像为基础的名为centos的容器
	docker run  --name=centos  -d  centos
	查看容器或者镜像的详细信息
	docker inspect centos
	强制删除所有容器实例,如果删除某个容器则将\$(docker ps -a -q)替换为某个容器名即可
	docker rm -f \$(docker ps -a -q)
	强制删除所有镜像,如果删除某个镜像则将\$(docker images -q -a)替换为某个镜像名即可
	docker rmi -f \$(docker images -q -a)
	进入容器名为centos里执行命令
	docker exec -it centos bin/bash
	容器导出
	docker export centos>centos.tar
	容器导入
	cat centos.tar| docker import - centos
	镜像导出
	docker save centos> /home/centos.tar
	镜像导入
	docker load < /home/centos.tar
	redis访问
	docker run -it --link myredis:redis --rm $DOCKER_REG_ADDR/redis redis-cli -h redis -p 6379
	docker run -it --rm $DOCKER_REG_ADDR/mysql mysql -h$IP -uroot -p 可以进行客户端操作
	========================主业务命令======================
	安装私服
	./docker-start.sh installDockerReg
	安装etcd
	./docker-start.sh installEtcd
	安装flannel
	./docker-start.sh installFlannel
	安装centos7ssh镜像
	./docker-start.sh installCentos7SSH
	安装hadoop镜像
	./docker-start.sh installHadoop
	安装redis镜像
	./docker-start.sh installRedis
	安装mysql镜像
	./docker-start.sh installMysql
	安装dubbo
	./docker-start.sh installDubboadmin
	基础必备镜像快速安装
	########
			installDockerReg
		    installEtcd
		    installFlannel
    ########
	./docker-start.sh step1

	业务部分快速安装
	########
			installCentos7SSH
		    installHadoop
			installRedis
		    installMysql
		    installDubboadmin
		    
    ########
	./docker-start.sh step2
	全部安装
	./docker-start.sh all
	===============================安装成功后，再次启动相关命令===================================
	启动hadoop组件
	./docker-start.sh startHadoop
	其他的
	docker start 容器名即可
	如果已经启动想再次重启要先docker stop 再start

	启动web监控
	./docker-start.sh startMonitorWeb
	清除所有安装
	./docker-start.sh clearAll
	其他机器如果要拉去私服镜像，初始化私服地址
	./docker-start.sh initRegistry
	EOF
}


for args in $@
do
	#从零安装部分
    if [ $args = "installDockerReg" ] ; then
        installDockerReg
    elif [ $args = "installEtcd" ] ; then
        installEtcd
    elif [ $args = "installFlannel" ] ; then
        installFlannel
    elif [ $args = "installCentos7SSH" ] ; then
        installCentos7SSH
    elif [ $args = "installHadoop" ] ; then
        installHadoop
    elif [ $args = "installRedis" ] ; then
        installRedis
    elif [ $args = "installMysql" ] ; then
        installMysql
   
    elif [ $args = "installDubboadmin" ] ; then
        installDubboadmin
    #基础快速安装
    elif [ $args = "step1" ] ; then
        installDockerReg
        installEtcd
        installFlannel
    #业务部分安装    
    elif [ $args = "step2" ] ; then
    	installCentos7SSH
        installHadoop
    	installRedis
        installMysql
        installDubboadmin
    elif [ $args = "all" ] ; then
    	startMonitorWeb

    	installDockerReg
        installEtcd
        installFlannel
        installCentos7SSH
        installHadoop

    	installRedis
        installMysql
        installDubboadmin
       
    elif [ $args = "startHadoop" ] ; then
        startHadoop
    elif [ $args = "startMonitorWeb" ] ; then
        startMonitorWeb
    elif [ $args = "clearAll" ] ; then
        clearAll
    elif [ $args = "initRegistry" ] ; then
        initRegistry
    #提交镜像到私服
    elif [ $args = "push" ] ; then
    	echo "提交hadoop镜像"
    	local dockername="centos7-ssh-jdk8-hadoop2.7-zookeeper3.4-hbase1.2"
    	docker push $DOCKER_REG_ADDR/$dockername
    	echo "提交ssh镜像到私服"
		docker push $DOCKER_REG_ADDR/centos7-ssh
        echo "提交redis镜像到私服"
		docker push $DOCKER_REG_ADDR/redis
		echo "提交mysql镜像到私服"
		docker push $DOCKER_REG_ADDR/mysql
    elif [ $args = "help" ] ; then
        help
    fi
done

