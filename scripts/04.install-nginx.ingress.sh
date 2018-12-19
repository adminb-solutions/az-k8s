#!/bin/bash

source /etc/environment

helm install stable/nginx-ingress --namespace ingress --name ingress  --set rbac.create="true",controller.extraArgs.enable-ssl-passthrough="true",controller.nodeSelector."beta\.kubernetes\.io/os"="linux",defaultBackend.nodeSelector."beta\.kubernetes\.io/os"="linux"
