#!/usr/bin/env bash

tanzu apps workload delete tanzu-java-web-app -n my-apps -y

tanzu secret registry delete registry-credentials -n my-apps -y 
unset KUBECONFIG
rm kubeconfig