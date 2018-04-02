---
title: "Kubernetes On Bare Metal"
date: 2018-04-01T21:01:44-04:00
draft: true
---

<div class="toc">
<strong>Table of Contents</strong>
<ul>
    <li><a href="#goals">Goals</a></li>
    <li><a href="#options">Options</a></li>
    <li><a href="#servers">Servers</a></li>
    <li><a href="#scripts">Init Scripts</a></li>
    <li><a href="#nfs-server">NFS Server</a></li>
    <li><a href="#master-node">Master Node</a></li>
    <li><a href="#worker-node">Worker Node(s)</a></li>
    <li><a href="#pod-networking">Pod Networking (Flannel)</a></li>
    <li><a href="#dashboard">Kubernetes Dashboard</a></li>
    <li><a href="#nfs-sc">NFS Storage Class</a></li>
    <li><a href="#helm">Installing Helm</a></li>
    <li><a href="#heapster">Installing Heapster</a></li>
    <li><a href="#traefik">Installing Traefik</a></li>
    <li><a href="#registry">Private Docker Registry</a></li>
    <li><a href="#creds">Configuring Credentials</a></li>
    <li><a href="#deploy">Deploying Your Applications</a></li>
    <li><a href="#cicd">Integrating with GitLab/CICD</a></li>
</ul>
</div>

If you've been following kubernetes, you'll understand theres a myriad of options available... I'll cover a few of them briefly and why I didn't choose them. Don't know what Kubernetes is? <a href="https://kubernetes.io/docs/getting-started-guides/minikube/" rel="nofollow">Minikube</a> is the best way to get going locally.

This guide will take you from nothing to a 2 node cluster, automatic SSL for deployed apps, a custom PVC/PV storage class using NFS, and a private docker registry. Helpful tips and bugs I ran into are sprinkled throughout their respective sections.

<a name="goals"></a>
##### But first the goals for this cluster:

* First-class SSL support with LetsEncrypt so we can easily deploy new apps with SSL using just annotations.
* Bare metal for this conversation means a regular VM/VPS provider or a regular private provider like Proxmox with no special services - or actual hardware.
* Not require anything *fancy* (like BIOS control)
* Be reasonably priced (<$50/month)
* Be reasonably production-y (*this is for side projects, not a huge business critical app*)
* Works with Ubuntu 16.04
* Works on Vultr (and others like Digital Ocean - providers that are (mostly) generic VM hosts and don't have specialized APIs and services like AWS/GCE)
* I also reccomend making sure your VM provider supports a software defined firewall and a private network - however this is not a hard requirement.



<a name="options"></a>
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

... And the *winner* is... <a href="https://github.com/kubernetes/kubeadm" rel="nofollow">Kubeadm</a>. It's not in any incubator stages and is documented as one of the official ways to get a cluster setup.

<a name="servers"></a>
##### Servers we'll need:

* $5 (+$5 for 50G block storage) - NFS Pod storage server ( 1 CPU / 1GB RAM / block storage )
* $5 - 1 Master node ( 1 CPU / 1G RAM )
* $20 - 1 Worker node ( 2 CPU / 4G RAM - you can choose what you want for this )
* $5 - *(optional)* DB server - due to bugs I've ran into in production environments with docker, and various <a href="https://www.youtube.com/watch?v=Nosa5-xcATw&feature=youtu.be&t=1080">smart people</a> saying not do it, and issues you can run into with file system consistency, I run a seperate DB server for my apps to connect to if they need it.

**Total cost:** $40.00

<a name="scripts"></a>
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

<a name="nfs-server"></a>
##### Setting up the NFS Server

I'm not going to go in depth on setting an NFS server, there's a million guides. I will however mention the exports section which I've kobbled together after a few experiments and reading OpenShift docs. There's also a good amount of documentation if you want to go the CEPH storage route as well, however NFS was the simplest solution to get setup.

Remember to lock down your server with a firewall so everything is locked down except internal network traffic to your VMs.

**/etc/exports**
{{< highlight bash >}}
/srv/kubestorage 10.99.0.0/255.255.255.0(rw,no_root_squash,no_wdelay,no_subtree_check)
{{< /highlight >}}
<br>

Export options:

* *no_root_squash* - this shouldn't be used for shared services, but if its for your own use and not accessed anywhere else this is fine. This lets the docker containers work with whatever user they're booting as without conflicting with permissions on the NFS server.
* *no_subtree_check* - prevents issues with files being open and renamed at the same time
* *no_wdelay* - generally prevents NFS from trying to be smart about when to write, and forces it to write to the disk ASAP.

<a name="master-node"></a>
#### Setting up the master node

On the master node run `kubeadm` to init the cluster and start kubernetes services:

{{< highlight bash >}}
kubeadm init --allocate-node-cidrs=true --cluster-cidr=10.244.0.0/16
{{< /highlight >}}

This will start the cluster and setup a pod network on `10.244.0.0/16` for internal pods to use.

Next you'll notice that the node is in a `NotReady` state when you do a `kubectl get nodes`. We need to setup our worker node next.

You can either continue using `kubectl` on the master node or copy the config to your workstation (depending on how your network permissions are setup):

{{< highlight bash >}}
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
{{< /highlight >}}


<a name="worker-node"></a>
#### Setting up the worker node

You'll get a token command to run on workers from the previous step. However if you need to generate new tokens later on when you're expanding your cluster, you can use `kubeadm token list` and `kubeadm token create` to get a new token.

**Important Note:** Your worker nodes **Must** have a unique hostname otherwise they will join the cluster and over-write each other (1st node will disappear and things will get rebalanced to the node you just joined). If this happens to you and you want to reset a node, you can run `kubeadm reset` to wipe that worker node.


<a name="pod-networking"></a>
#### Setting up pod networking (Flannel)


Back on the **master** node we can add our Flannel network overlay. This will let the pods reside on different worker nodes and communicate with eachother over internal DNS and IPs.

{{< highlight bash >}}
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
{{< /highlight >}}

After a few seconds you should see output from `kubectl get nodes` similar to this (depending on hostnames):

{{< highlight bash >}}
root@k8s-master:~# kubectl get nodes
NAME           STATUS    ROLES     AGE       VERSION
k8s-master     Ready     master    4d        v1.10.0
k8s-worker     Ready     <none>    4d        v1.10.0
{{< /highlight >}}

<a name="dashboard"></a>
#### Deploying the Kubernetes Dashboard

If you need more thorough documentation, head on over to the [dashboard repo](https://github.com/kubernetes/dashboard#getting-started). We're going to follow a vanilla installation:


{{< highlight bash >}}
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
{{< /highlight >}}

Once that is installed you need to setup a `ServiceAccount` that can request tokens and use the dashboard, so save this to `dashboard-user.yaml`:

{{< highlight yaml >}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
{{< /highlight >}}

and then apply it


{{< highlight bash >}}
kubectl apply -f dashboard-user.yaml
{{< /highlight >}}

Next you'll need to grab the service token for the dashbord authentication and fire up `kube proxy`:

{{< highlight bash >}}
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d '\t'
kube proxy
{{< /highlight >}}

Now you can access the dashboard at [http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login).

<a name="nfs-sc"></a>
#### Setting up our NFS storage class

When using a cloud provider you normally get a default storage class provided for you (like on GKE). With our bare metal installation if we want `PersistentVolumes` (PVs)
and `PersistentVolumeClaims` (PVCs) to work, we need to set up our own private storage class.

We'll be using [nfs-client](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client) from the incubator for this.

The best way to do this is to clone the repo and go to the `nfs-client` directory and edit the following files:

* `deploy/class.yaml`: This is what your storage will be called in when setting up storage and from `kubectl get sc`:

{{< highlight yaml >}}
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: joshrendek.com/nfs # or choose another name, must match deployment's env PROVISIONER_NAME'
{{< /highlight >}}

* `deploy/deployment.yaml`: you **must** make sure your provisioner name matches here and that you have your NFS server IP set properly and the mount your exporting set properly.

Create a file called `nfs-test.yaml`:

{{< highlight yaml >}}
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim
  annotations:
    volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
---
kind: Pod
apiVersion: v1
metadata:
  name: test-pod
spec:
  containers:
  - name: test-pod
    image: gcr.io/google_containers/busybox:1.24
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "touch /mnt/SUCCESS && exit 0 || exit 1"
    volumeMounts:
      - name: nfs-pvc
        mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
    - name: nfs-pvc
      persistentVolumeClaim:
        claimName: test-claim
{{< /highlight >}}


Next just follow the repository instructions:

{{< highlight bash >}}
kubectl apply -f deploy/deployment.yaml
kubectl apply -f deploy/class.yaml
kubectl create -f deploy/auth/serviceaccount.yaml
kubectl create -f deploy/auth/clusterrole.yaml
kubectl create -f deploy/auth/clusterrolebinding.yaml
kubectl patch deployment nfs-client-provisioner -p '{"spec":{"template":{"spec":{"serviceAccount":"nfs-client-provisioner"}}}}'
kubectl patch storageclass managed-nfs-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
{{< /highlight >}}

This creates all the RBAC permissions, adds them to the deployment, and then sets the default storage class provider in your cluster. You should see something similar when running `kubectl get sc` now:

{{< highlight bash >}}
NAME                            PROVISIONER           AGE
managed-nfs-storage (default)   joshrendek.com/nfs   4d
{{< /highlight >}}

Now lets test our deployment and check the NFS share for the SUCCESS file:

{{< highlight bash >}}
kubectl apply -f nfs-test.yaml
{{< /highlight >}}

If everything is working, move on to the next sections, you've gotten NFS working! The only problem I ran into at this point was mis-typing my NFS Server IP.
You can figure this out by doing a `kubectl get events -w` and watching the mount command output and trying to replicate it on the command line from a worker node.

<a name="helm"></a>
#### Installing Helm

Up until this point we've just been using `kubectl apply` and `kubectl create` to install apps. We'll be using helm to manage our applications and install things going forward for the most part.

If you don't already have helm installed (and are on OSX): `brew install kubernetes-helm`, otherwise hop on over to the [helm website](https://docs.helm.sh/using_helm/#installing-helm) for installation instructions.

First we're going to create a `helm-rbac.yaml`:

{{< highlight yaml >}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: tiller-clusterrolebinding
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: ""
{{< /highlight >}}

Now we can apply everything:

{{< highlight bash >}}
kubectl create -f helm-rbac.yaml
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --upgrade
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
{{< /highlight >}}

First we install the RBAC permissions, service accounts, and role bindings. Next we install helm and initalize tiller on the server. Tiller keeps track of which apps are deployed where and when they need updates. Finally we tell the tiller deployment about its new `ServiceAccount`.

You can verify things are working with a `helm ls`. Next we can install our first application, `Heapster`.

**Important Helm Note**: Helm is great, but sometimes it breaks. If your deployments/upgrades/deletes are hanging, try bouncing the tiller pod:

{{< highlight bash >}}
kubectl delete po -n kube-system -l name=tiller
{{< /highlight >}}


<a name="heapster"></a>
#### Installing Heapster

Heapster provides in cluster metrics and health information:

{{< highlight bash >}}
helm install stable/heapster --name heapster --set rbac.create=true
{{< /highlight >}}

You should see it installed with a `helm ls`.


<a name="traefik"></a>
#### Installing Traefik (LoadBalancer)

First lets create a `traefik.yaml` values file:

{{< highlight yaml >}}
serviceType: NodePort
externalTrafficPolicy: Cluster
replicas: 2
cpuRequest: 10m
memoryRequest: 20Mi
cpuLimit: 100m
memoryLimit: 30Mi
debug:
  enabled: false
ssl:
  enabled: true
acme:
  enabled: true
  email: your_email@example.com
  staging: false
  logging: true
  challengeType: http-01
  persistence:
    enabled: true
    annotations: {}
    accessMode: ReadWriteOnce
    size: 1Gi
dashboard:
  enabled: true
  domain: # YOUR DOMAIN HERE
  auth:
    basic:
      admin: # FILL THIS IN WITH A HTPASSWD VALUE
gzip:
  enabled: true
accessLogs:
  enabled: false
  ## Path to the access logs file. If not provided, Traefik defaults it to stdout.
  # filePath: ""
  format: common  # choices are: common, json
rbac:
  enabled: true
## Enable the /metrics endpoint, for now only supports prometheus
## set to true to enable metric collection by prometheus

deployment:
  hostPort:
    httpEnabled: true
    httpsEnabled: true
{{< /highlight >}}

Important things to note here are the `hostPort` setting - with multiple worker nodes this lets us specify multiple A records for some level of redundancy and binds them to the **host** ports of 80 and 443 so they can receive HTTP and HTTPS traffic. The other important setting is to use `NodePort` so we use the worker nodes IP to expose ourselves (normally in something like GKE or AWS we would be registering with an ELB, and that ELB would talk to our k8s cluster).

Let's also make a `traefik-ui.yaml` file:

{{< highlight yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: traefik-web-ui
  namespace: kube-system
spec:
  selector:
    k8s-app: traefik-ingress-lb
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: traefik-web-ui
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: traefik.sub.yourdomain.com
    http:
      paths:
      - backend:
          serviceName: traefik-dashboard
          servicePort: 80

{{< /highlight >}}

Now lets install `traefik` and the dashboard:

{{< highlight bash >}}
helm install stable/traefik --name traefik -f traefik.yaml --namespace kube-system
kubectl apply -f traefik-ui.yaml
{{< /highlight >}}

You can check the progress of this with `kubectl get po -n kube-system -w`. Once everything is registered you should be able to go `https://traefik.sub.yourdomain.com` and login to the dashboard with the basic auth you configured.

<a name="registry"></a>
#### Private Docker Registry

Provided you got everything working in the previous step (HTTPS works and LetsEncrypt got automatically setup for your traefik dashboard) you can continue on.

First we'll be making a `registry.yaml` file with our custom values:

{{< highlight yaml >}}
replicaCount: 1
persistence:
  accessMode: 'ReadWriteOnce'
  enabled: true
  size: 10Gi
  # storageClass: '-'
# set the type of filesystem to use: filesystem, s3
storage: filesystem
secrets:
  haSharedSecret: ""
  htpasswd: "YOUR_DOCKER_USERNAME:GENERATE_YOUR_OWN_HTPASSWD_FOR_HERE"
{{< /highlight >}}

Next lets make a traefik service definition in `traefik-registry.yaml`:

{{< highlight yaml >}}
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: docker-web
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: registry.sub.yourdomain.com
    http:
      paths:
      - backend:
          serviceName: registry-docker-registry
          servicePort: 5000
{{< /highlight >}}

And putting it all together:

{{< highlight bash >}}
helm install -f registry.yaml --name registry stable/docker-registry
kubectl apply -f traefik-registry.yaml
{{< /highlight >}}

Provided all that worked, you should now be able to push and pull images and login to your registry at `registry.sub.yourdomain.com`

<a name="creds"></a>
#### Configuring docker credentials (per namespace)

There are several ways you can set up docker auth (like `ServiceAccounts`) or `ImagePullSecrets` - I'm going to show the latter.

Take your docker config that should look something like this:

{{< highlight json >}}
{
        "auths": {
                "registry.sub.yourdomain.com": {
                        "auth": "BASE64 ENCODED user:pass"
                }
        }
}
{{< /highlight >}}

and base64 encode that whole file/string. Make it all one line and then create a `registry-creds.yaml` file:


{{< highlight yaml >}}
apiVersion: v1
kind: Secret
metadata:
 name: regcred
 namespace: your_app_namespace
data:
 .dockerconfigjson: BASE64_ENCODED_CREDENTIALS
type: kubernetes.io/dockerconfigjson
{{< /highlight >}}


Create your app namespace: `kubectl create namespace your_app_namespace` and apply it.

{{< highlight bash >}}
kubectl apply -f registry-creds.yaml
{{< /highlight >}}

You can now delete this file (or encrypt it with GPG, etc) - just don't commit it anywhere. Base64 encoding a string won't protect your credentials.

You would then specify it in your helm `delpoyment.yaml` like:

{{< highlight yaml >}}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    metadata:
      labels:
        app: {{ template "fullname" . }}
    spec:
      imagePullSecrets:
        - name: regcred
{{< /highlight >}}

<a name="deploy"></a>
#### Deploying your own applications

I generally make a `deployments` folder then do a `helm create app_name` in there. You'll want to edit the `values.yaml` file to match your docker image names and vars.


You'll need to edit the templates/ingress.yaml file and make sure you have a traefik annotation:

{{< highlight yaml >}}
  annotations:
    kubernetes.io/ingress.class: traefik
{{< /highlight >}}

And finally here is an example `deployment.yaml` that has a few extra things from the default:

{{< highlight yaml >}}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: {{ template "fullname" . }}
  labels:
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    metadata:
      labels:
        app: {{ template "fullname" . }}
    spec:
      imagePullSecrets:
        - name: regcred
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.io/hostname"
            labelSelector:
              matchLabels:
                app:  {{ template "fullname" . }}
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.service.internalPort }}
        livenessProbe:
          httpGet:
            path: /
            port: {{ .Values.service.internalPort }}
          initialDelaySeconds: 5
          periodSeconds: 30
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: {{ .Values.service.internalPort }}
          initialDelaySeconds: 5
          timeoutSeconds: 5
        resources:
{{ toYaml .Values.resources | indent 10 }}
{{< /highlight >}}

On line 14-15 we're specifying our registry credentials we created in the previous step.

Assuming a replica count >= 2, Lines 16-22 are telling kubernetes to schedule the pods on different worker nodes. This will prevent both web servers (for instance) from being put on the same node incase one of them crashes.

Lines 29-41 are going to depend on your app - if your server is slow to start up these values may not make sense and can cause your app to constantly go into a `Running`/ `Error` state and getting its containers reaped by the liveness checks.

And provided you just have configuration changes to try out (container is already built and in a registry), you can iterate locally:

{{< highlight yaml >}}
helm upgrade your_app_name . -i --namespace your_app_name --wait --debug
{{< /highlight >}}

<a name="cicd"></a>
#### Integrating with GitLab / CICD Pipelines
