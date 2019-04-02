#!/usr/bin/env bash

indent() {
  INDENT="      "
  sed "s/^/$INDENT/" | sed "s/^${INDENT}\($1\)/${INDENT:0:-2}- \1/"
}

CRDDIR=${DIR:-$(cd $(dirname "$0")/../deploy/crds && pwd)}
PKGDIR=${DIR:-$(cd $(dirname "$0")/../deploy/olm-catalog/tektoncd-operator && pwd)}
CSVDIR=${DIR:-$(cd ${PKGDIR}/0.0.1 && pwd)}

NAME=${NAME:-tektoncd-operators}
x=( $(echo $NAME | tr '-' ' ') )
DISPLAYNAME=${DISPLAYNAME:=${x[*]^}}

CRD=$(cat $(ls $CRDDIR/*crd.yaml) | grep -v -- "---" | indent apiVersion)
CSV=$(cat $(ls $CSVDIR/*version.yaml) | indent apiVersion)
PKG=$(cat $(ls $PKGDIR/*package.yaml) | indent packageName)

cat <<EOF | sed 's/^  *$//'
---
apiVersion: v1
kind: Namespace
metadata:
 name: tekton-pipelines
---
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
 name: og-tekton-operator
 namespace: tekton-pipelines
spec:
 targetNamespaces:
 - tekton-pipelines
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: $NAME
  namespace: tekton-pipelines
spec:
  configMap: $NAME
  displayName: $DISPLAYNAME
  publisher: Red Hat
  sourceType: internal
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: $NAME
  namespace: tekton-pipelines
data:
  customResourceDefinitions: |-
$CRD
  clusterServiceVersions: |-
$CSV
  packages: |-
$PKG
EOF
