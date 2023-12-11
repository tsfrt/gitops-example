
# Air-gapped  install

## relocate images
kbld image relocation will not work with velero because init container plugin images use special conventions to locate datamanager and backup-driver images.

### pull
docker pull velero/velero:v1.12.2
docker pull velero/velero-plugin-for-aws:v1.8.2
docker pull vsphereveleroplugin/velero-plugin-for-vsphere:v1.5.2
docker pull vsphereveleroplugin/backup-driver:v1.5.2
docker pull vsphereveleroplugin/data-manager-for-plugin:v1.5.2

### tag (use your repo)
docker tag velero/velero:v1.12.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero:v1.12.2
docker tag velero/velero-plugin-for-aws:v1.8.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-aws:v1.8.2
docker tag vsphereveleroplugin/velero-plugin-for-vsphere:v1.5.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-vsphere:v1.5.2
docker tag vsphereveleroplugin/backup-driver:v1.5.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/backup-driver:v1.5.2
docker tag vsphereveleroplugin/data-manager-for-plugin:v1.5.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/data-manager-for-plugin:v1.5.2

### push (use your repo)
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero:v1.12.2
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-aws:v1.8.2
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-vsphere:v1.5.2
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/backup-driver:v1.5.2
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/data-manager-for-plugin:v1.5.2

## Helm chart

set your repo

```yaml

image:
  repository: harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero
  tag: v1.12.2

```

Set the init containers

```yaml
initContainers:
- name: vsphereveleroplugin-velero-plugin-for-vsphere
  image: harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-vsphere:v1.5.2
  imagePullPolicy: IfNotPresent
  volumeMounts:
    - mountPath: /target
      name: plugins
- name: velero-velero-plugin-for-aws
  image:  harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-aws:v1.8.2
  imagePullPolicy: IfNotPresent
  volumeMounts:
    - mountPath: /target
      name: plugins
```

see the values file secret example [valero-values-secert.yaml](cluster-config/shared-services/velero-values-secret.yaml)