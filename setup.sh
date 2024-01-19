#!/bin/bash
set -e

kind create cluster --name=issue-provider-kubernetes
kubectx kind-issue-provider-kubernetes

kubectl create namespace upbound-system

helm install uxp --namespace upbound-system upbound-stable/universal-crossplane --devel --version 1.14.5-up.1
kubectl -n upbound-system wait --for=condition=Available deployment --all --timeout=5m

kubectl apply -f examples/provider.yaml
kubectl apply -f examples/function.yaml

kubectl wait provider.pkg --all --for condition=Healthy --timeout 5m
kubectl wait function.pkg --all --for condition=Healthy --timeout 5m

kubectl apply -f examples/providerconfig.yaml
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount=upbound-system:provider-kubernetes-63506a3443e0 

kubectl apply -f apis/composition.yaml
kubectl apply -f apis/definition.yaml

kubectl wait xrd --all --for condition=Established

kubectl apply -f examples/xr.yaml

sleep 30

kubectl get managed
kubectl apply -f examples/provider-update.yaml

sleep 30

# service-account changes after update ;)
kubectl delete clusterrolebinding provider-kubernetes-admin-binding
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount=upbound-system:provider-kubernetes-0b6a1dd69062

kubectl apply -f apis/composition-update.yaml

sleep 30

kubectl describe xtest 
