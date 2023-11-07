# Relocate Chart to Registry

## Bundle Chart

```bash
helm repo add harbor https://helm.goharbor.io

helm pull harbor/harbor 

helm registry login -u admin harbor.build.h2o-2-18171.h2o.vmware.com --ca-file ~/Downloads/harbor.build.new.cer

helm push harbor-1.13.0.tgz

helm push harbor-1.13.0.tgz oci://harbor.build.h2o-2-18171.h2o.vmware.com/charts --ca-file ~/Downloads/harbor.build.new.cer 

#you may want to use values here if certain images get included conditionally
helm template harbor harbor-1.13.0.tgz | kbld -f- --lock-output harbor.lock

kbld pkg -f harbor.lock --output harbor-package.tar

kbld unpkg -f harbor.lock --input harbor-package.tar --repository harbor.build.h2o-2-18171.h2o.vmware.com/charts/harbor-bundle --lock-output harbor.lock.copied

helm show values harbor/harbor > harbor-values.yaml

kubectl create secret generic harbor-values --from-file=harbor-values.yaml -o yaml  > harbor/harbor-values-secret.yaml

kubectl create secret generic harbor-values --from-file=harbor-values.yaml -o yaml --dry-run=client > harbor/harbor-values-secret.yaml
```

## Values Encryption

```bash
age-keygen -o key.txt
export SOPS_AGE_RECIPIENTS=$(cat /Users/seufertt/gitops/private/key.txt | grep "# public key: " | sed 's/# public key: //')\n
SOPS_AGE_KEY_FILE=/Users/seufertt/gitops/private/key.txt sops --encrypt --age age12345  harbor-values-secret.yaml > harbor-values-secret.sops.yam 
```

## App Definition

```yaml

apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: harbor-helm
  namespace: package-repo
spec:
  deploy:
  - kapp:
      intoNs: harbor-test
  fetch:
  - helmChart:
      name: harbor
      repository:
        url: oci://harbor.build.h2o-2-18171.h2o.vmware.com/charts
      version: 1.13.0
  - git:
      ref: origin/main
      subPath: harbor/harbor-artifacts
      url: https://github.com/tsfrt/gitops-example
  serviceAccountName: kapp-gitops-sa
  template:
  - sops:
      age:
        privateKeysSecretRef:
          name: enc-key
  - helmTemplate:
      path: 0/
      valuesFrom:
      - secretRef:
          name: harbor-values
  - kbld:
      paths:
      - 1/harbor.lock.copied
      - '-'
  template:
  - helmTemplate:
      valuesFrom:
      - secretRef:
          name: concourse-values
   deploy:
  - kapp: {}

```