FROM hub.c.163.com/library/centos:centos7.3.1611
RUN echo "安装ssh"
RUN yum install -y openssl openssh-server
RUN yum install -y openssh-clients
RUN yum install net-tools -y
COPY makessh.sh /home/
RUN chmod u+x /home/makessh.sh


RUN echo "修改root密码"
RUN echo "root:root" | chpasswd
RUN echo "设置免密码登录"
RUN echo "修改端口为2022，避免与主机端口冲突"
RUN sed -i "s/#Port 22/Port 2022/g" /etc/ssh/sshd_config
RUN sed -i "s/#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN sed -i "s/#RSAAuthentication yes/RSAAuthentication yes/g" /etc/ssh/sshd_config
RUN sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
RUN sed -i "s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g" /etc/ssh/ssh_config

#RUN mkdir ~/.ssh
#COPY id_rsa.pub /root/.ssh/authorized_keys
#COPY ssh_host_rsa_key  /etc/ssh/
#COPY ssh_host_ecdsa_key  /etc/ssh/
#COPY ssh_host_ed25519_key  /etc/ssh/
#RUN ssh-keygen  -t rsa -P ''
#RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
#RUN ssh-keygen -t rsa -P '' -f /etc/ssh/ssh_host_rsa_key
#RUN ssh-keygen -t ecdsa -P '' -f /etc/ssh/ssh_host_ecdsa_key
#RUN ssh-keygen -t ed25519 -P '' -f /etc/ssh/ssh_host_ed25519_key
#RUN ps -ef | grep sshd|awk '{ print $2 }' | xargs kill -9
CMD /usr/sbin/sshd -D



