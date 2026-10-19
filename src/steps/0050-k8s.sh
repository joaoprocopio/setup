#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
KUBERNETES_VERSION=v1.35

apt_source kubernetes \
  "https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key" \
  "https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/" /
apt_install kubectl
