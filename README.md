# bare-metal-kubernetes

WORK IN PROGRESS;

## Limitations not to waste time
currently init-cluster is limited to ubuntu, my local host system, but later will implement to run on 
several CPU architectures (within reasonable approach) and multiple OS's. ARM being a focus.


## Purpose of this project
Learning and having a flexible cluster management repo obv

## Initiating the cluster

`sudo chmod +x ./init-cluster.sh`

## References and material
- (Docker install on ubuntu) https://docs.docker.com/engine/install/ubuntu/
- (Kind for running local clusters) https://kind.sigs.k8s.io/
- (terraform installation) https://developer.hashicorp.com/terraform/install
- (installing kubectl) https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
- (community docs) https://github.com/kubernetes/community

## todo
### init-cluster.sh
- migrate to individual functions instead of single monolithic mess
  - add standard error handling to functions


## Acknowledgments
Created with love and frustration from an burned out IT dude.
