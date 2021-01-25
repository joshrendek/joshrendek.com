---
title: 'Affordable logging for kubernetes and side projects'
date: 2020-11-29T00:46:27-04:00
draft: true
---

```bash 
curl -L -O https://raw.githubusercontent.com/elastic/beats/6.0/deploy/kubernetes/filebeat-kubernetes.yaml\n
curl -L -O https://raw.githubusercontent.com/elastic/beats/7.10/deploy/kubernetes/metricbeat-kubernetes.yaml\n
```

```yaml
# get ssh key from logging
# helm repo add elastic https://helm.elastic.co
# helm install apm-server --version 7.10 elastic/apm-server
# edit apm config to point to logging forwarder: k edit cm apm-server-apm-server-config
# kubectl create secret generic logging-ssh-key --from-file=id_rsa=logging_ssh_key
apiVersion: v1
kind: ConfigMap
metadata:
  name: "logging-ssh-forwarder-script"
data:
  start.sh: |
    #!/bin/sh
    apk add --update openssh-client curl
    mkdir ~/.ssh
    ssh-keyscan -H logging.bluescripts.net >> ~/.ssh/known_hosts
    ssh -i /etc/ssh-key/id_rsa -N -o GatewayPorts=true -L 9200:0.0.0.0:9200 ubuntu@logging.bluescripts.net
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
