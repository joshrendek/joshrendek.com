---
title: "Helm not updating image, how to fix"
date: 2018-07-16T21:56:43-04:00
draft: false
categories: ['kubernetes', 'helm']
---

If you have your `imagePullPolicy: Always` and deploys aren't going out (for example if you're using a static tag, like `stable`) - then you may be running into a helm templating bug/feature.

If your helm template diff doesn't change when being applied the update won't go out, even if you've pushed a new image to your docker registry.

A quick way to fix this is to set a commit sha in your CICD pipeline, in GitLab for example this is `$CI_COMMIT_SHA`.

If you template this out into a `values.yaml` file and add it as a label on your `Deployment` - when you push out updates your template will be different from the remote, and tiller and helm will trigger an update provided you've set it properly, for example:

``` yaml
script:
    - helm upgrade -i APP_NAME -i --set commitHash=$CI_COMMIT_SHA
```
