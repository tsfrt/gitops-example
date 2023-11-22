#!/usr/bin/env bash

BASEDIR=$(dirname "$0")

while getopts a: flag
do
    case "${flag}" in
        a) app=${OPTARG};;
    esac
done

kubectl apply -f ${BASEDIR}/../cluster-apps/gitops-prereqs.yaml
kubectl apply -f ${BASEDIR}/../cluster-apps/${app}.yaml 