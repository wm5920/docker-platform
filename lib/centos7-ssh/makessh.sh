#!/bin/bash
# echo "修改root密码"
# echo "root:root" | chpasswd
# echo "设置免密码登录"
# echo "修改端口为2022，避免与主机端口冲突"
# sed -i "s/#Port 22/Port 2022/g" /etc/ssh/sshd_config
# sed -i "s/#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
# sed -i "s/#RSAAuthentication yes/RSAAuthentication yes/g" /etc/ssh/sshd_config
# sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
# sed -i "s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g" /etc/ssh/ssh_config

echo "生成秘钥,ssh-keygen  -t rsa 指定文件就不行，不指定文件难道还有什么其他操作吗"
mkdir ~/.ssh
ssh-keygen  -t rsa -P ''
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
ssh-keygen -t rsa -P '' -f /etc/ssh/ssh_host_rsa_key
ssh-keygen -t ecdsa -P '' -f /etc/ssh/ssh_host_ecdsa_key
ssh-keygen -t ed25519 -P '' -f /etc/ssh/ssh_host_ed25519_key
ps -ef | grep sshd|awk '{ print $2 }' | xargs kill -9
/usr/sbin/sshd -D &
echo "可以输入ssh localhost -p 2022 进行测试，不需要密码验证则成功，然后exit即可"
