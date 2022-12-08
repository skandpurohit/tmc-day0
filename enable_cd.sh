#!/bin/bash

echo "=========================================="
echo "Setting Predefined Variables"

mgmt_cluster_name=my-tkg-poc-cluster
read -p "Provide Cluster Name: " cluster_name
echo "Cluster Name : $cluster_name"
provisioner=default
git_repo=https://github.com/skandpurohit/tmc-cd.git
echo "=========================================="
echo ""

# setup kubeconfig and context
echo ""
echo "=========================================="
echo "Setup kubeconfig from TMC cli and update context in local machine"
cp ~/.kube/config ~/.kube/config.bak
tmc cluster auth kubeconfig get $cluster_name -m $mgmt_cluster_name > ~/.kube/temp/kubeconfig-$cluster_name
KUBECONFIG=~/.kube/config:~/.kube/temp/kubeconfig-$cluster_name kubectl config view --flatten > ~/.kube/temp/config
mv ~/.kube/temp/config ~/.kube/config 
kubectx $cluster_name
echo "=========================================="
echo ""

# Enable CD (4-5 mins)
echo ""
echo "=========================================="
tmc cluster fluxcd continuousdelivery enable -m $mgmt_cluster_name -p $provisioner --cluster-name $cluster_name
echo "Process will take about 4-5 mins to complete"
sleep 240
echo "$cluster_name cluster now has Continous Delivery enabled. "
echo "=========================================="


# Create Repo Creds
echo "creating git repo creds"
echo "=========================================="
tmc cluster fluxcd sourcesecret create --cluster-name $cluster_name --name tmc-cd-secret --username skandpurohit --password $git_password --type basic
sleep 15
echo "Repo Creds Successfully Generated and added to TMC"
echo "=========================================="
echo ""


# Git Repo
echo "add git repo to cd"
echo "=========================================="
tmc cluster fluxcd gitrepository create -c $cluster_name -n tmc-cd --secret-ref tmc-cd-secret --url "$git_repo"
echo "Git Repo added, reconciling ....... "
sleep 20
echo "=========================================="
echo ""


# Add kustomization
echo "enable kustomization"
echo "=========================================="
tmc cluster fluxcd kustomization create -c $cluster_name -n tmc-cd-kustomization --path / --prune --source-name tmc-cd
echo "=========================================="
echo ""
