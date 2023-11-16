## Apply a cluster profile


Apply prereqs

```bash
kubectl apply -f cluster-apps/gitops-prereqs.yaml
```
Create your encryption key and secret

```bash
age-keygen -o key.txt

kubectl create secret generic enc-key --from-file==key-txt --dry-run=client -o yaml > enc-key.yaml
```

Take the output of this and create a yaml secret like this (you could use secretgen to duplicate, but should just be these 2 namespaces)

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: enc-key
  namespace: tkg-system
stringData:
  key.txt: |
    # created: 2023-11-07T08:28:54-05:00
    # public key: age1k0pw8ujs33xpk0sjuxex64nqhz4c4j5yhus3lka077sv868rv4qq4upsu4
    AGE-SECRET-KEY-1LCH9QTZLSVLUVX8HE07RFPSN8PJF8JGPLJZ3LF6ZSUYLYP64FW6QMM5D0Q
---
apiVersion: v1
kind: Secret
metadata:
  name: enc-key
  namespace: package-repo
stringData:
  key.txt: |
    # created: 2023-11-07T08:28:54-05:00
    # public key: age1k0pw8ujs33xpk0sjuxex64nqhz4c4j5yhus3lka077sv868rv4qq4upsu4
    AGE-SECRET-KEY-1LCH9QTZLSVLUVX8HE07RFPSN8PJF8JGPLJZ3LF6ZSUYLYP64FW6QMM5D0Q
```

Apply the key secrets

```bash
kubectl apply -f enc-key.yaml
```

Create any required cluster specific cluster-config (for example encrypted harbor values)

```bash
#this is an example for a profile with harbor
#there could be any number of cluster specific configurations 
#they don't need to be encrypted if they are not sensative

SOPS_AGE_KEY_FILE=/Users/seufertt/gitops/private/key.txt sops --encrypt --age <pub key>  harbor-values.yaml > harbor-values.sops.yaml

cp harbor-values.sops.yaml cluster-config/<profile name>
```

Check out your cluster-app profile, does it have all the services you want

```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: shared-services
  namespace: tkg-system
spec:
  serviceAccountName: kapp-gitops-sa  
  fetch:
  - git:
      url: https://github.com/tsfrt/gitops-example
      ref: origin/main
  template:
  - sops:
      age:
        privateKeysSecretRef:
          name: enc-key
  - ytt:
      ignoreUnknownComments: true
      paths:
      - common
      - cluster-config/shared-services
      - standard-repo
      - cert-manager
      - contour
      - harbor/app
  deploy:
  - kapp: {}
```

If so, apply the profile

```bash
kubectl apply -f cluster-app/<profile app>.yaml
```
