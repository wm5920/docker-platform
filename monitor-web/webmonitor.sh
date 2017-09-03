#!/bin/bash
echo  "内存占用统计"
echo  "separator"
free -m
echo  "separator"
echo   "资源占用统计"
echo  "separator"
df -h
echo  "separator"
echo  "硬盘占用情况"
echo  "separator"
fdisk -l
echo  "separator"
echo  "正在运行的docker"
echo  "separator"
docker ps

liveDocker=""
if [ "$(docker ps|grep hadoop-master)" != "" ] ; then
    liveDocker="$liveDocker"" hadoop-master "
fi
if [ "$(docker ps|grep hadoop-node1)" != "" ] ; then
    liveDocker="$liveDocker"" hadoop-node1 "
fi
if [ "$(docker ps|grep hadoop-node2)" != "" ] ; then
    liveDocker="$liveDocker"" hadoop-node2 "
fi
if [ "$(docker ps|grep myredis)" != "" ] ; then
    liveDocker="$liveDocker"" myredis "
fi
if [ "$(docker ps|grep mysql)" != "" ] ; then
    liveDocker="$liveDocker"" mysql "
fi
if [ "$(docker ps|grep dubbo)" != "" ] ; then
    liveDocker="$liveDocker"" dubbo "
fi
if [ "$(docker ps|grep sso)" != "" ] ; then
    liveDocker="$liveDocker"" sso "
fi
if [ "$(docker ps|grep sms)" != "" ] ; then
    liveDocker="$liveDocker"" sms "
fi
if [ "$(docker ps|grep devicedata)" != "" ] ; then
    liveDocker="$liveDocker"" devicedata "
fi
if [ "$(docker ps|grep monitor)" != "" ] ; then
    liveDocker="$liveDocker"" monitor "
fi
if [ "$(docker ps|grep opcua)" != "" ] ; then
    liveDocker="$liveDocker"" opcua "
fi
if [ "$(docker ps|grep modbus)" != "" ] ; then
    liveDocker="$liveDocker"" modbus "
fi
if [ "$(docker ps|grep self)" != "" ] ; then
    liveDocker="$liveDocker"" self "
fi
if [ "$(docker ps|grep rdms-web)" != "" ] ; then
    liveDocker="$liveDocker"" rdms-web "
fi
if [ "$(docker ps|grep registry)" != "" ] ; then
    liveDocker="$liveDocker registry "
fi
echo -e "\n查看各容器资源占用情况\n"
if [ "$liveDocker" != "" ] ; then
	docker stats $liveDocker --no-stream
fi


echo  "separator"
echo  "主机docker镜像"
echo  "separator"
docker images

# docker stats hadoop-node3 hadoop-master hadoop-node2 hadoop-node1 rdms-web self modbus opcua monitor devicedata sms sso dubbo mysql myredis   --no-stream

# availfree=`free -m|grep Mem|awk '{print $2-$3}'`
# availdisk=`df |grep home|awk '{print $4/1024}'`
# echo " $1  $2  $availfree $availdisk"
# if [ $1 -gt $availfree ] ; then
#      echo  "内存不够用了,当前剩余内存$availfree M,低于$1 M "
# fi

# if [ $2 -gt $availdisk ] ; then
#      echo  "磁盘不够用了,当前剩余容量$availdisk M,低于$2 M "
# fi