#!/usr/bin/env bash

set -eo pipefail

BASEDIR=$(dirname "$0")

while getopts ":a:k:u:t:b:r": flag
do
    case "${flag}" in
        a) app=${OPTARG};;
        k) kf=${OPTARG};;
        u) gu=${OPTARG};;
        t) gt=${OPTARG};;
        b) branch=${OPTARG};;
        r) repo=${OPTARG};;
    esac 
done

if [ -z "$app" ]; then
    echo 'Option -a missing, should be cluster name' >&2
    exit 1
fi

if [ -z "$kf" ]; then
    echo 'Option -k missing, should be path to age key file' >&2
    exit 1
fi

if [ -z "$gu" ]; then
    echo 'Option -u missing, should be your git user' >&2
    exit 1
fi

if [ -z "$gt" ]; then
    echo 'Option -t missing, should be your git token' >&2
    exit 1
fi

if [ -z "$branch" ]; then
    echo 'Option -b missing, should be your git branch' >&2
    exit 1
fi

if [ -z "$repo" ]; then
    echo 'Option -r missing, should be your git repo' >&2
    exit 1
fi

if [ ! -d "${BASEDIR}/../cluster-config/${app}" ]; then
    echo "Cluster config not found ${BASEDIR}/../cluster-config/${app}"
    exit 1
fi

echo About to apply to: $(kubectl config current-context)
read -p "Press enter to continue"

kubectl apply -f ${BASEDIR}/../cluster-apps/gitops-prereqs.yaml

kubectl delete secret  git-creds \
--ignore-not-found \
-n tkg-system

kubectl create secret generic git-creds \
  --from-literal=username=${gu} \
  --from-literal=password=${gt} \
  -n tkg-system

kubectl delete secret enc-key \
--ignore-not-found \
-n tkg-system

kubectl create secret generic enc-key \
  --from-file=key.txt=${kf} \
  -n tkg-system

kubectl delete secret enc-key \
--ignore-not-found \
-n package-repo

kubectl create secret generic enc-key \
  --from-file=key.txt=${kf} \
  -n package-repo

cat <<EOF | kubectl apply -f -
---
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: ${app}
  namespace: tkg-system
spec:
  serviceAccountName: kapp-gitops-sa
  fetch:
    - git:
        url: ${repo}
        ref: ${branch}
        secretRef:
          name: git-creds 
  template:
    - sops:
        age:
          privateKeysSecretRef:
            name: enc-key
    - ytt:
        fileMarks:
        - data.yaml:type=data
        - packages.yaml:type=data
        ignoreUnknownComments: true
        paths:
          - common
          - cluster-config/${app}
        valuesFrom:
          - secretRef:
              name: cluster-data
  deploy:
    - kapp: {}
EOF