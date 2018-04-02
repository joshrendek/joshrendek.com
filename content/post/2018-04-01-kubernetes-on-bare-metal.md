---
title: "Kubernetes On Bare Metal"
date: 2018-04-01T21:01:44-04:00
draft: true
---

If you've been following kubernetes, you'll understand theres a myriad of options available... I'll cover a few of them briefly and why I didn't choose them. Don't know what Kubernetes is? <a href="https://kubernetes.io/docs/getting-started-guides/minikube/" rel="nofollow">Minikube</a> is the best way to get going locally.

##### But first the goals for this cluster:

* Bare metal for this conversation means a regular VM/VPS provider or a regular private provider like Proxmox with no special services - or actual hardware.
* Not require anything *fancy* (like BIOS control)
* Be reasonably priced (<$50/month)
* Be reasonably production-y (*this is for side projects, not a huge business critical app*)
* Works with Ubuntu 16.04
* Works on Vultr (and others like Digital Ocean - providers that are (mostly) generic VM hosts and don't have specialized APIs and services like AWS/GCE)
* I also reccomend making sure your VM provider supports a software defined firewall and a private network - however this is not a hard requirement.


##### Overview of Options

* <a href="https://www.openshift.org/" rel="nofollow">OpenShift</a>: Owned by RedHat - uses its own special tooling around `oc`. Minimum requirements were to high for a small cluster. Pretty high vendor lockin.
* <a href="https://github.com/kubernetes-incubator/kubespray" rel="nofollow">KubeSpray</a>: unstable. It used to work pretty consistently around 1.6 but when trying to spin up a 1.9 cluster and 1.10 cluster it was unable to finish. I am a fan of Ansible, and if you are as well, this is the project to follow I think.
* Google Kubernetes Engine: Attempting to stay away from cloud-y providers so outside of the scope of this. If you want a managed offering and are okay with GKE pricing, this is the way to go.
* AWS: Staying away from cloud-y providers. Cost is also a big factor here since this is a side-project cluster.
* <a href="https://coreos.com/tectonic/" rel="nofollow">Tectonic</a>: Requirements are to much for a small cloud provider/installation ( PXE boot setup, Matchbox, F5 LB ).
* <a href"https://github.com/kubernetes/kops" rel="nofollow">Kops</a>: Only supports AWS and GCE.
* <a href="https://kubernetes.io/docs/getting-started-guides/ubuntu/installation/#juju-deploy" rel="nofollow">Canonical Juju</a>: Requires MAAS, attempted to use but kept getting errors around lxc. Seems to favor cloud provider deploys (AWS/GCE/Azure).
* <a href="https://github.com/kubicorn/kubicorn" rel="nofollow">Kubicorn</a>: No bare metal support, needs cloud provider APIs to work.
* <a href="https://rancher.com/" rel="nofollow">Rancher</a>: Rancher is pretty awesome, unfortunately it's *incredibly* easy to break the cluster and break things inside Rancher that make the cluster unstable. It does provide a very simple way to play with kubernetes on whatever platform you want.

... And the *winner* is... <a href="https://github.com/kubernetes/kubeadm" rel="nofollow">Kubeadm</a>.

##### Servers we'll need:

* $5 (+$5 for 50G block storage) - NFS Pod storage server ( 1 CPU / 1GB RAM / block storage )
* $5 - 1 Master node ( 1 CPU / 1G RAM )
* $20 - 1 Worker node ( 2 CPU / 4G RAM - you can choose what you want for this )
* $5 - *(optional)* DB server - due to bugs I've ran into in production environments with docker, and various <a href="https://www.youtube.com/watch?v=Nosa5-xcATw&feature=youtu.be&t=1080">smart people</a> saying not do it, and issues you can run into with file system consistency, I run a seperate DB server for my apps to connect to if they need it.

**Total cost:** $40.00

##### Base Worker + Master init-script

{{< highlight bash >}}
#!/bin/sh
apt-get update
apt-get upgrade -y
apt-get -y install python
IP_ADDR=$(echo 10.99.0.$(ip route get 8.8.8.8 | awk '{print $NF; exit}' | cut -d. -f4))
cat <<- EOF >> /etc/network/interfaces
auto ens7
iface ens7 inet static
    address $IP_ADDR
    netmask 255.255.0.0
    mtu 1450
EOF
ifup ens7

apt-get install -y apt-transport-https
apt -y install docker.io
systemctl start docker
systemctl enable docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni nfs-common

reboot
{{< /highlight >}}

Lines 2-13 will run on server boot up, install python (used so Ansible can connect and do things later), update and upgrade everything, and then add the private network address. Since Vultr gives you a
true private network I'm cheating a bit and just using the last octect of the
public IP to define my internal LAN IP.

Line 16 we're installing the Ubuntu packaged version of docker -- this is important. There are a lot of tools that don't bundle the proper docker version to go along with their k8s installation and that can cause all kinds of issues, including everything not working due to version mismatches.

Lines 15-22 we're installing the kubernetes repo tools for kubeadm and kubernetes itself.

##### Setting up the NFS Server

I'm not going to go in depth on setting an NFS server, there's a million guides. I will however mention the exports section which I've kobbled together after a few experiments and reading OpenShift docs. There's also a good amount of documentation if you want to go the CEPH storage route as well, however NFS was the simplest solution to get setup.

Remember to lock down your server with a firewall so everything is locked down except internal network traffic to your VMs.

**/etc/exports**
```
/srv/kubestorage 10.99.0.0/255.255.255.0(rw,no_root_squash,no_wdelay,no_subtree_check)
```
<br>

Export options:

* *no_root_squash* - this shouldn't be used for shared services, but if its for your own use and not accessed anywhere else this is fine. This lets the docker containers work with whatever user they're booting as without conflicting with permissions on the NFS server.
* *no_subtree_check* - prevents issues with files being open and renamed at the same time
* *no_wdelay* - generally prevents NFS from trying to be smart about when to write, and forces it to write to the disk ASAP.

#### Setting up the master node

On the master node run `kubeadm` to init the cluster and start kubernetes services:

{{< highlight bash >}}
kubeadm init --allocate-node-cidrs=true --cluster-cidr=10.244.0.0/16
{{< /highlight >}}

This will start the cluster and setup a pod network on `10.244.0.0/16` for internal pods to use.

Next you'll notice that the node is in a `NotReady` state when you do a `kubectl get nodes`. We need to setup our worker node next.

#### Setting up the worker node

You'll get a token command to run on workers from the previous step. However if you need to generate new tokens later on when you're expanding your cluster, you can use `kubeadm token list` and `kubeadm token create` to get a new token.

**Important Note:** Your worker nodes **Must** have a unique hostname otherwise they will join the cluster and over-write each other. If this happens to you and you want to reset a node, you can run `kubeadm reset` to wipe that worker node.
