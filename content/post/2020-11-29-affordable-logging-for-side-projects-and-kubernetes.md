---
title: 'Affordable logging for kubernetes hobby projects'
date: 2020-11-29T00:46:27-04:00
categories: ['kubernetes']
draft: false
---

Having a useable logging and metrics stack for your hobby projects can extremely expensive if you 
stick them inside your kubernetes cluster or try and host them on a normal VPS provider (whether that means DigitalOcean or AWS).

Below is an example configuration I use for some hobby projects that uses a dedicated hosting provider (OVH).

This solves two main problems for me: hosting it securely (not exposing anything other than SSH) and having a beefy 
enough box to run elastic search and apm.

This is a small setup script that locks down the logging server to only allow SSH and installs the ELK stack,

On the logging server:

``` bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch kibana
vi /etc/elasticsearch/jvm.options
service elasticsearch start
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable
```


Next, we need to download and apply the filebeat and metric beat configs,

On the kubernetes cluster:

```bash 
curl -L -O https://raw.githubusercontent.com/elastic/beats/6.0/deploy/kubernetes/filebeat-kubernetes.yaml
curl -L -O https://raw.githubusercontent.com/elastic/beats/7.10/deploy/kubernetes/metricbeat-kubernetes.yaml
kubectl apply -f filebeat-kuberentes.yaml
kubectl apply -f metricbeat-kubernetes.yaml
```

Then we'll need to create a SSH key to get into the logging server. You can create the secret with a given ssh private key,

Locally:

```bash
kubectl create secret generic logging-ssh-key --from-file=id_rsa=logging_ssh_key
```

Install the APM server,

On the kubernetes cluster:

```bash 
helm repo add elastic https://helm.elastic.co
helm install apm-server --version 7.10 elastic/apm-server
```


Create the below as a yaml file manifest and apply it with `kubectl apply -f filename.yaml`.

1. Setup a config map with a startup script that will port-forward 9200 over SSH to the logging server
2. Deploy a service into the cluster to allow local services to talk to it
3. Setup health checks and liveness probes to restart the pod if the SSH connection gets interrupted
4. Mounts the SSH key for the pod to connect from a secret

```yaml
# get ssh key from logging
apiVersion: v1
kind: ConfigMap
metadata:
  name: "logging-ssh-forwarder-script"
data:
  start.sh: |
    #!/bin/sh
    apk add --update openssh-client curl
    mkdir ~/.ssh
    ssh-keyscan -H logging.exmaple.com >> ~/.ssh/known_hosts
    ssh -i /etc/ssh-key/id_rsa -N -o GatewayPorts=true -L 9200:0.0.0.0:9200 user@logging.example.com
---
apiVersion: v1
kind: Service
metadata:
  name: logging-forwarder
spec:
  selector:
    run: logging-forwarder
  ports:
    - protocol: TCP
      port: 9200
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: filebeat-ssh-forwarder
spec:
  selector:
    matchLabels:
      run: logging-forwarder
  replicas: 1
  template:
    metadata:
      labels:
        run: logging-forwarder
    spec:
      containers:
        - name: forwarder
          image: alpine:latest
          command:
            - "/start"
          ports:
            - containerPort: 9200
          livenessProbe:
            exec:
              command:
                - curl
                - localhost:9200
          readinessProbe:
            exec:
              command:
                - curl
                - localhost:9200
          volumeMounts:
            - name: ssh-key-volume
              mountPath: "/etc/ssh-key"
            - name: logging-ssh-forwarder-script
              mountPath: /start
              subPath: start.sh
      volumes:
        - name: logging-ssh-forwarder-script
          configMap:
            name: logging-ssh-forwarder-script
            defaultMode: 0755
        - name: ssh-key-volume
          secret:
            secretName: logging-ssh-key
            defaultMode: 256
```


Lastly you'll need to change the APM server to point to our new service,

On the kubernetes cluster:

```bash 
kubectl edit cm apm-server-apm-server-config
```

You can now connect to your ELK stack and view APM metrics and other logs flowing into your cluster:

```bash
ssh -L 5601:127.0.0.1:5601 user@logging.example.com
```

And open your browser to http://localhost:5601

Here is an example of the APM dashboard in Kibana under Observability -> Overview

![](/images/monitoring/apm.png)

And that's it. Make sure you setup index policies to rotate large indexes so the disks don't get full.
