FROM DOCKER_REG_ADDR/centos7-ssh
#===========================配置jdk==========================="
#jdk
RUN mkdir -p /home/jdk/jdk1.8.0_111
ENV JAVA_HOME /home/jdk/jdk1.8.0_111
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH $PATH:$JAVA_HOME/bin
#hadoop
#===========================配置hadoop==========================="
COPY hadoop-2.7.3 /home/hadoop-2.7.3
RUN chmod u+x /home/hadoop-2.7.3/sbin/*
RUn chmod u+x /home/hadoop-2.7.3/bin/*
ENV HADOOP_HOME /home/hadoop-2.7.3
ENV PATH $PATH:$HADOOP_HOME/bin

#"安装which命令,hadoop需要用到"
RUN yum -y install which

#"添加hadoop控制脚本"
COPY start.sh /home/
COPY addhosts.sh /home/
COPY config.sh /home/
COPY create.sh /home/
RUN chmod u+x /home/start.sh
RUN chmod u+x /home/addhosts.sh
RUN chmod u+x /home/config.sh
RUN chmod u+x /home/create.sh
#===========================配置zookeeper==========================="
ADD zookeeper-3.4.6.tar.gz /home/
ENV ZOOKEEPER_HOME /home/zookeeper-3.4.6/
ENV PATH $PATH:$ZOOKEEPER_HOME/bin

#===========================配置hbase==========================="
COPY hbase-1.2.3 /home/hbase-1.2.3
RUN chmod u+x /home/hbase-1.2.3/bin/*
ENV HBASE_HOME /home/hbase-1.2.3/
ENV PATH $PATH:$HBASE_HOME/bin
ADD apache-phoenix-4.9.0-HBase-1.2-bin.tar.gz  /home/
RUN cp /home/apache-phoenix-4.9.0-HBase-1.2-bin/phoenix-4.9.0-HBase-1.2-server.jar /home/hbase-1.2.3/lib/