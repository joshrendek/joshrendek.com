---
title: "Faster Local Dev With Minikube"
date: 2018-06-05T18:23:15-04:00
draft: false
---

If your developing against kubernetes services or want to run your changes without pushing to a remote registry and want to run inside kubernetes:

First create a registry running in minikube:

``` bash
kubectl create -f https://gist.githubusercontent.com/joshrendek/e2ec8bac06706ec139c78249472fe34b/raw/6efc11eb8c2dce167ba0a5e557833cc4ff38fa7c/kube-registry.yaml
```

Forward your localhost:5000 to 5000 on minikube:

``` bash
kubectl port-forward --namespace kube-system $(kubectl get po -n kube-system | grep kube-registry-v0 | awk '{print $1;}') 5000:5000
```

Use minikube's docker daemon and then push to localhost:5000

``` bash
eval $(minikube docker-env)
docker push localhost:5000/test-image:latest
```

And then you can do you helm charts and deploys using localhost. No need to configure default service account creds or getting temporary creds.

Using localhost eliminates the need to use insecure registry settings removing a lot of docker daemon configuration steps.
