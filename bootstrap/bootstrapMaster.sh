#!/usr/bin/env bash

KUBEJOIN="/vagrant/tmp/kubejoin.sh"

yum -y install screen yum-plugin-downloadonly tree htop vim net-tools unzip git nfs-utils
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
modprobe br_netfilter && \
sleep 3 && \
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
swapoff -a
sed -i '/swapfile/d' /etc/fstab
cat <<EOMESSAGE > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOMESSAGE
#yum install kubeadm docker -y
yum install kubeadm-1.18.3 kubectl-1.18.3 kubelet-1.18.3 docker -y

cat <<EOMESSAGE > /etc/docker/daemon.json
{
    "live-restore": true,
    "group": "dockerroot"
}
EOMESSAGE
usermod -aG dockerroot vagrant
systemctl restart docker && systemctl enable docker
systemctl restart kubelet && systemctl enable kubelet

# only for master:
KUBEINITLOG="/root/kubeinit.log"
VHOME="/home/vagrant"

echo "Kubernetes initialization (can take few minutes)..."
kubeadm init --apiserver-advertise-address 192.168.7.100 --pod-network-cidr=10.244.0.0/16 > $KUBEINITLOG

grep "kubeadm join" -A1 $KUBEINITLOG >> $KUBEJOIN
mkdir -p $VHOME/.kube
cp -n /etc/kubernetes/admin.conf $VHOME/.kube/config
chown -R vagrant.vagrant $VHOME/.kube
mkdir /root/.kube
cp -n /etc/kubernetes/admin.conf /root/.kube/config
kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/canal.yaml
