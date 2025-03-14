#!/bin/bash

kubectl delete ns vpp
kubectl create ns vpp
kubectl create -n vpp configmap vpp-startup-config --from-file=/runner/_work/userspace-cni-network-plugin/userspace-cni-network-plugin/docker/vpp-centos-userspace-cni/startup.conf

worker="kind-control-plane"


rm /opt/cni/bin/userspace
docker exec -i kind-control-plane bash -c "mkdir -p /var/run/vpp/app"

cat << EOF | kubectl apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: userspacecni-$worker
  namespace: vpp
spec:
  nodeSelector:
    kubernetes.io/hostname: $worker
  containers:
  - name: userspacecni-$worker
    image: userspacecni:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: cni
      mountPath: /opt/cni/bin
  volumes:
    - name: cni
      hostPath:
        path: /opt/cni/bin
  restartPolicy: Never
EOF


echo "sleeping for 20 to allow userspace to deploy first"
sleep 20

cat << EOF | kubectl apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: vpp-$worker
  labels:
    name: vpp
  namespace: vpp
spec:
  nodeSelector:
    kubernetes.io/hostname: $worker
  hostname: vpp-$worker
  subdomain: vpp
  containers:
  - image: ligato/vpp-base:23.02 #imagename
    imagePullPolicy: IfNotPresent
    name: vpp-$worker
    volumeMounts:
    - name: vpp-api
      mountPath: /run/vpp/
    - name: vpp-run
      mountPath: /var/run/vpp/
    - name: vpp-startup-config
      mountPath: /etc/vpp/
    - name: hugepage
      mountPath: /hugepages
    - name: userspace-api
      mountPath: /var/lib/cni/usrspcni/
    resources:
      requests:
        hugepages-2Mi: 1Gi
        memory: "1Gi"
        cpu: "3"
      limits:
        hugepages-2Mi: 1Gi
        memory: "1Gi"
        cpu: "3"
  restartPolicy: Always
  volumes:
    - name: vpp-run
      hostPath:
        path: /var/run/vpp/
    - name: vpp-api
      hostPath:
        path: /run/vpp/
    - name: userspace-api
      hostPath:
        path: /var/lib/cni/usrspcni/
    - name: vpp-startup-config
      configMap:
        name: vpp-startup-config
    - name: hugepage
      emptyDir:
        medium: HugePages
EOF

