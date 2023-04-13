#!/bin/bash

# Use this script if you are on an AMI that is already to run openshift-install
# This script should be used to create a new cluster

if [[ -d /openshift ]]
then
    rm -rf /openshift
fi

mkdir -p /openshift/install_dir /openshift/original
cat <<_EOF >/openshift/install_dir/install-config.yaml
apiVersion: v1
baseDomain: $BASEDOMAIN
metadata:
  name: $LOCATION 
credentialsMode: Manual
controlPlane:   
  hyperthreading: Enabled 
  name: master
  platform:
    aws:
      zones:
      - ${REGION}a
      - ${REGION}b
      - ${REGION}c
      rootVolume:
        iops: 3000
        size: $CPDISKGB
        type: gp3 
      type: $CPTYPE
  replicas: $CPLANES
compute: 
- hyperthreading: Enabled 
  name: worker
  platform:
    aws:
      rootVolume:
        iops: 3000
        size: $WORKDISKGB
        type: gp3 
      type: $WORKTYPE
      zones:
      - ${REGION}a
      - ${REGION}b
      - ${REGION}c
  replicas: $WORKERS
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: ${REGION}
    amiID: $AMI
fips: false 
sshKey: $SSHKEY
pullSecret: '{"auths":{"fake":{"auth": "bar"}}}' 
_EOF

cp /openshift/install_dir/install-config.yaml /openshift/original

# HTPassword data for finishing cluster and making users
cat <<_EOF >/openshift/htpasswd
admin:$apr1$XpV8XpLt$3V6wIySh17gzxjXHFtTcs1
developer:$apr1$wukRz8Ub$l1RDzxyRbX6U3WCBrn/xY0
_EOF

# Install cluster
cd /openshift
nohup openshift-install create cluster --dir install_dir --log-level info &

echo "Cluster is installing, use:"
echo "If your terminal does lock, just log back in and do the following:"
echo "cd /openshift"
echo "tail -f nohup.out"
echo "At the end of the install if successful you will see:"
echo "INFO Time elapsed: 35m39s"
echo "You should also see the URL for the Web console and the password"
tail -f nohup.out