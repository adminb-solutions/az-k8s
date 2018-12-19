#!/bin/bash

source /etc/environment

helm init --upgrade --node-selectors "beta.kubernetes.io/os"="linux"

while ! helm version &> /dev/null ; do
    sleep 1s
done

helm version
