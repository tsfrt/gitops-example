
# Air-gapped  install

## relocate images
kbld image relocation will not work with velero because init container plugin images use special conventions to locate datamanager and backup-driver images.

### pull
```
docker pull velero/velero:v1.12.2
docker pull velero/velero-plugin-for-aws:v1.8.2
docker pull vsphereveleroplugin/velero-plugin-for-vsphere:v1.5.2
docker pull vsphereveleroplugin/backup-driver:v1.5.2
docker pull vsphereveleroplugin/data-manager-for-plugin:v1.5.2
```
### tag (use your repo)
```
docker tag velero/velero:v1.12.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero:v1.12.2
docker tag velero/velero-plugin-for-aws:v1.8.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-aws:v1.8.2
docker tag vsphereveleroplugin/velero-plugin-for-vsphere:v1.5.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-vsphere:v1.5.2
docker tag vsphereveleroplugin/backup-driver:v1.5.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/backup-driver:v1.5.2
docker tag vsphereveleroplugin/data-manager-for-plugin:v1.5.2 harbor.build.h2o-2-18171.h2o.vmware.com/velero/data-manager-for-plugin:v1.5.2
```
### push (use your repo)
```
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero:v1.12.2
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-aws:v1.8.2
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/velero-plugin-for-vsphere:v1.5.2
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/backup-driver:v1.5.2
docker push harbor.build.h2o-2-18171.h2o.vmware.com/velero/data-manager-for-plugin:v1.5.2
```
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

Configure minio

* You can grab the minio ca cert from the minio instance TLS secret (if using TLS)

* create a bucket through the minio console or the mc cli, my bucket is called `ops2`

Create an access secret for minio based on your instances credentials

```
[default]
aws_access_key_id=TE9HPBKGGLXJTK1F5A8F
aws_secret_access_key=l6r4obH2dAYdPoFnAaMsR00ZjeqVm1GDX87FaPOr
```

Turn this file into a secret and encrypt it

```
kubectl create secret generic minio-access-secret --from-file=secret=secret --dry-run=client -n velero -o yaml > minio-access-secret.yaml

SOPS_AGE_KEY_FILE=/Users/seufertt/gitops/private/key.txt sops --encrypt --age age1k0pw8ujs33xpk0sjuxex64nqhz4c4j5yhus3lka077sv868rv4qq4upsu4 minio-access-secret.yaml > minio-access-secret.sops.yaml
```

Fill out the helm values for the datasource with this config.  You can also create or edit the `backupstoragelocation` after installing the chart.

```yaml
 # provider is the name for the backup storage location provider.
        provider: aws
        # bucket is the name of the bucket to store backups in. Required.
        bucket: ops2
        # caCert defines a base64 encoded CA bundle to use when verifying TLS connections to the provider. Optional.
        caCert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURwRENDQW95Z0F3SUJBZ0lSQU1pS2JTSThBUEtNSi9vdWtrMVN3TGd3RFFZSktvWklodmNOQVFFTEJRQXcKRlRFVE1CRUdBMVVFQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TXpFeU1URXdNak00TXpsYUZ3MHlOREV5TVRBdwpNak00TXpsYU1HSXhGVEFUQmdOVkJBb1RESE41YzNSbGJUcHViMlJsY3pGSk1FY0dBMVVFQXd4QWMzbHpkR1Z0Ck9tNXZaR1U2S2k1dGFXNXBieTEwWlc1aGJuUXRNUzFvYkM1dGFXNXBieTEwWlc1aGJuUXRNUzV6ZG1NdVkyeDEKYzNSbGNpNXNiMk5oYkRCWk1CTUdCeXFHU000OUFnRUdDQ3FHU000OUF3RUhBMElBQkRlcVNiQXlGcTFiMWNhTQpFdndOT3d2R0NQMUprSGZieVF6UTU3dUNEM2VGdnVBaGtzR1BMeHE5ZW5rSlljc01lNUFmc3ZuemJsR2prZk4wCmpwNGRBcStqZ2dGck1JSUJaekFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdFd0RBWURWUjBUQVFIL0JBSXdBREFmQmdOVkhTTUVHREFXZ0JRZVk3eWM2eG1pdUxvei9pZERoekdpMjVxbQpZRENDQVE4R0ExVWRFUVNDQVFZd2dnRUNnazV0YVc1cGJ5MTBaVzVoYm5RdE1TMXpjeTB3TFhzd0xpNHVNMzB1CmJXbHVhVzh0ZEdWdVlXNTBMVEV0YUd3dWJXbHVhVzh0ZEdWdVlXNTBMVEV1YzNaakxtTnNkWE4wWlhJdWJHOWoKWVd5Q0ptMXBibWx2TG0xcGJtbHZMWFJsYm1GdWRDMHhMbk4yWXk1amJIVnpkR1Z5TG14dlkyRnNnaFJ0YVc1cApieTV0YVc1cGJ5MTBaVzVoYm5RdE1ZSVliV2x1YVc4dWJXbHVhVzh0ZEdWdVlXNTBMVEV1YzNaamdqUXFMbTFwCmJtbHZMWFJsYm1GdWRDMHhMV2hzTG0xcGJtbHZMWFJsYm1GdWRDMHhMbk4yWXk1amJIVnpkR1Z5TG14dlkyRnMKZ2lJcUxtMXBibWx2TFhSbGJtRnVkQzB4TG5OMll5NWpiSFZ6ZEdWeUxteHZZMkZzTUEwR0NTcUdTSWIzRFFFQgpDd1VBQTRJQkFRQnlFYVlPWUxBWjRQKzlnc2RzNGh1eFBWV3EyNlUzT2VXNXNzZjk1OGMzZU1xQ3JMc0NpZHZxClZsYUZrc3RGdGVtTEJHUys2QzkvL29waENTQU9LREdObWU4ejFwTUtnZ0Evb3UvODZYZFlSanZBdk5tb09hMUIKamEvcGdwQXY1Yis3aHIwbkxrcEJMNmIrQ29JMHl0Rk9YZFpHV2xsN2VDbUc5L05DZDVwNVZpbTM2Vm5wektYUApFb29HbjBHdFl3aHUzc1JwMFM3MFNjYURUbG00cEJNQm84UjcwMHhoc2NINTBEaVBtK2tWbVJMQmJIK3pqbHp1CmtkZnNRQ3cvWXBWWVg1Smk1TERrZHRSSExzbkpSR2NhY292NTVLc01OVlJVUzZyVkpxZ3hQK29ObmVCTVhoaTEKQUx5bHFaM1hGZllzalk4L0pxdjlCWUc2TXl3Q1M3S0MKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
        # prefix is the directory under which all Velero data should be stored within the bucket. Optional.
        prefix:
        # default indicates this location is the default backup storage location. Optional.
        default:
        # validationFrequency defines how frequently Velero should validate the object storage. Optional.
        validationFrequency:
        # accessMode determines if velero can write to this backup storage location. Optional.
        # default to ReadWrite, ReadOnly is used during migrations and restores.
        accessMode: ReadWrite
        credential:
          # name of the secret used by this backupStorageLocation.
          name: minio-access-secret
          # name of key that contains the secret data to be used.
          key: secret
        # Additional provider-specific configuration. See link above
        # for details of required/optional fields for your provider.
        config:
          region: us-east-1
          s3ForcePathStyle: true
          s3Url: https://minio.minio-tenant-1.svc.cluster.local
        #  kmsKeyId:
        #  resourceGroup:
        #  The ID of the subscription containing the storage account, if different from the cluster’s subscription. (Azure only)
        #  subscriptionId:
        #  storageAccount:
        #  publicUrl:
        #  Name of the GCP service account to use for this backup storage location. Specify the
        #  service account here if you want to use workload identity instead of providing the key file.(GCP only)
        #  serviceAccount:
        #  Option to skip certificate validation or not if insecureSkipTLSVerify is set to be true, the client side should set the
        #  flag. For Velero client Command like velero backup describe, velero backup logs needs to add the flag --insecure-skip-tls-verify
          insecureSkipTLSVerify: true
    
```

### Helm app

Note that 

`lock_file` is set to none to prevent tags from being set to digests

`name` must be velero, not velero-app or velero-helm

```
#@ name = "velero"  <--- deployment must be named velero
#@ namespace = "velero"
#@ chart_name = "velero"
#@ chart_url = "oci://harbor.build.h2o-2-18171.h2o.vmware.com/charts"
#@ package_name = "velero/app"
#@ git_ref = "origin/main"
#@ git_subpath = "velero/artifacts"
#@ git_repo = "https://github.com/tsfrt/gitops-example"
#@ lock_file = None  <--- lock file not set
```

see the values file secret example [valero-values-secert.yaml](cluster-config/shared-services/velero-values-secret.yaml)


