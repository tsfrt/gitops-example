# Relocate Chart to Registry

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


```yaml
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: harbor-helm
spec:
  fetch:
  - helmChart:
      name: harbor/harbor
      repository: oci://harbor.build.h2o-2-18171.h2o.vmware.com/charts/harbor:1.13.0
  - git:
      url: https://github.com/tsfrt/gitops-example
      ref: origin/main
      subPath: harbor/harbor-artifacts


  template:
  - helmTemplate:
      valuesFrom:
      - secretRef:
          name: concourse-values

   deploy:
  - kapp: {}

```