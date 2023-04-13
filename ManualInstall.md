# Install OpenShift 4 on AWS

## Pre-requisites

You will need an AWS Access Key and Secret.  This is obtained through IAM/Users/YourUserName if you have access.  Scroll down to **Access Keys**. Click the **Generate access key** button.

Create the AWS cli config;
```
aws configure
AWS Access Key ID [None]: ********
AWS Secret Access Key [None]: **********
Default region name [None]: ap-south-1
Default output format [None]: json
```

## The provisioning VM

1. t2.micro with 25GB RAM
2. Security group with the following open to all
    - 22/SSH
    - 80/HTTP
    - 443/HTTPS
    - 8080
    - 8443
    - All traffic to 172.31.0.0/16
3. SSH Key
    ```bash
    ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N ""
    echo "Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null" >$HOME/.ssh/config
    ```
4. Install the tools
    ```bash
    sudo su -
    cd /var/tmp
    RELEASE=4.12.0-0.okd-2023-03-18-084815
    # RELEASE=4.5.0-0.okd-2020-07-29-070316  # Causes boot issues with CoreOS 37 which is the only release
    # RELEASE=4.12.0-0.okd-2023-01-21-055900
    wget https://github.com/okd-project/okd/releases/download/$RELEASE/openshift-client-linux-$RELEASE.tar.gz
    wget https://github.com/okd-project/okd/releases/download/$RELEASE/openshift-install-linux-$RELEASE.tar.gz
    tar xvf openshift-client-linux-$RELEASE.tar.gz
    tar xvf openshift-install-linux-$RELEASE.tar.gz
    mv kubectl oc openshift-install /usr/bin
    rm -f *.tar.gz README.md
    exit
    ```
5. Create cluster
    ```bash
    openshift-install create cluster --dir install_dir --log-level=info
    > aws
    > ap-south-1  (select region to build in)
    > Base Domain: openshift.conygre.com
    > Cluster Name: india  (change to region)
    > Pull Secret: This must be a valid Red Hat OpenShift pull secret.

    INFO Creating infrastructure resources...

    INFO Waiting up to 20m0s (until 11:38AM) for the Kubernetes API at https://api.india.openshift.conygre.com:6443...

    INFO API v1.25.0-2786+eab9cc98fe4c00-dirty up
    
    INFO Waiting up to 30m0s (until 11:53AM) for bootstrapping to complete...

    INFO Destroying the bootstrap resources...

    INFO Waiting up to 40m0s (until 12:18PM) for the cluster at https://api.india.openshift.conygre.com:6443 to initialize...

    INFO Checking to see if there is a route at openshift-console/console...

    INFO Install complete!

    INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/root/install_dir/auth/kubeconfig'

    INFO Access the OpenShift web-console here: https://console-openshift-console.apps.india.openshift.conygre.com

    INFO Login to the console with user: "kubeadmin", and password: "HhYGB-IGKu5-BCagY-QwBPw"

    INFO Time elapsed: 35m39s
    ```

    - This uses m6i.xlarge x 3 for ControlPlanes 4vCPU x 16GB, 120GB disk
    - 3 Load balancers
    - 3 Elastic IPs
    - 4 Security Groups
    - 3 works m6i.xlarge 120GB
    - 1 bootstrap m6i.xlarge 30GB 
      - This machine is terminated after install
    - Created an extra DNS Zone
    - Started 12:09
    - Finished 12:48

**NOTE:** The login details can also be found on the machine that you ran **openshift-install** on in the **auth** directory.  This includes that **kubeadmin** password and the **kubeconfig** file.


# Shut down and start up

## Stopping

https://docs.openshift.com/container-platform/4.12/backup_and_restore/graceful-cluster-shutdown.html

**You can shutdown and restart within a year of install, after that the certs expire**

Run;

```bash
for node in $(oc get nodes -o jsonpath='{.items[*].metadata.name}')
do 
    oc debug node/${node} -- chroot /host shutdown -h 1
done 
```

Change the -h 1 to number of hours for shutdown.

This command does actually shutdown the VMs too.

## Starting

https://www.redhat.com/en/blog/how-stop-and-start-production-openshift-cluster

Start in order of;
- Control Plane
- Worker

You don't have to wait as the cluster should sort itself out.

Takes about 5 minutes to stabalise and get the web ui.  Use;

```
oc get nodes
```
To check all nodes came up.

## Adding users

- Log in to the UI.
- Go to User Management
- Users
- Click **cluster OAuth configuration** at the top of the screen
- Add the following in htpassword
    ```
    admin:$apr1$XpV8XpLt$3V6wIySh17gzxjXHFtTcs1
    developer:$apr1$wukRz8Ub$l1RDzxyRbX6U3WCBrn/xY0
    ```
- Before htpasswd shows up you may need to log on to the cluster using ```oc login -u developer```, or just wait a short while.

# Customising Install

https://docs.openshift.com/container-platform/4.10/installing/installing_aws/installing-aws-customizations.html

You need an install-config.yaml.

When running;

openshift-install create cluster --dir ./install-config.yaml --log-level=info

# Deleting the cluster

```
openshift-install destroy cluster --dir ./install_dir --log-level info

INFO Credentials loaded from the "default" profile in file "/root/.aws/credentials"

INFO Disassociated                                 id=i-00b371325bc006d9a name=india-xdxxn-master-profile role=india-xdxxn-master-role

INFO Deleted                                       InstanceProfileName=india-xdxxn-master-profile arn=arn:aws:iam::586390904014:instance-profile/india-xdxxn-master-profile id=i-00b371325bc006d9a

INFO Disassociated                                 id=i-0f7227e5c9a6b06ec name=india-xdxxn-worker-profile role=india-xdxxn-worker-role

INFO Deleted                                       InstanceProfileName=india-xdxxn-worker-profile arn=arn:aws:iam::586390904014:instance-profile/india-xdxxn-worker-profile id=i-0f7227e5c9a6b06ec

INFO Deleted                                       id=acd9642bd3bf1449a8acaf78a6f048d8
INFO Disassociated                                 id=rtbassoc-00f49836ea100b1ed
INFO Deleted                                       id=rtb-0601419e9b281503e
INFO Deleted                                       id=india-xdxxn-openshift-ingress-t4pb6 policy=india-xdxxn-openshift-ingress-t4pb6-policy
INFO Deleted                                       id=india-xdxxn-openshift-ingress-t4pb6
INFO Deleted                                       id=nat-0fd2375e295c2a35b
INFO Deleted                                       id=india-xdxxn-cloud-credential-operator-iam-ro-skvcs policy=india-xdxxn-cloud-credential-operator-iam-ro-skvcs-policy
INFO Deleted                                       id=india-xdxxn-cloud-credential-operator-iam-ro-skvcs
INFO Deleted                                       id=india-xdxxn-master-role name=india-xdxxn-master-role policy=india-xdxxn-master-policy
INFO Deleted                                       id=india-xdxxn-master-role name=india-xdxxn-master-role
INFO Deleted
INFO Deleted                                       id=india-xdxxn-worker-role name=india-xdxxn-worker-role policy=india-xdxxn-worker-policy
INFO Deleted                                       id=india-xdxxn-worker-role name=india-xdxxn-worker-role
INFO Deleted                                       id=net/india-xdxxn-ext/e1ecebb3454adc32
INFO Deleted                                       id=net/india-xdxxn-int/9ad06c4396882f4c
INFO Deleted                                       id=nat-0a85dbda115083743
INFO Deleted                                       id=eni-0a5008eb82bbe8c33
INFO Disassociated                                 id=rtbassoc-085c8098beae06f2e
INFO Deleted                                       id=rtb-092d935e2b47e4ca5
INFO Deleted                                       id=india-xdxxn-aext/e550cf6493c63303
INFO Disassociated                                 id=rtbassoc-0227a586c1a5296a7
INFO Deleted                                       id=rtb-022458b9cda9361bf
INFO Deleted                                       id=india-xdxxn-aws-ebs-csi-driver-operator-48qjj policy=india-xdxxn-aws-ebs-csi-driver-operator-48qjj-policy
INFO Deleted                                       id=india-xdxxn-aws-ebs-csi-driver-operator-48qjj
INFO Deleted                                       id=india-xdxxn-aint/6469c7689cffab72
INFO Deleted                                       NAT gateway=nat-0c644c2dad367d7d2 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0a85dbda115083743 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0fd2375e295c2a35b id=vpc-033b9645884e8df1e
INFO Disassociated                                 id=rtbassoc-043ea77be9c1a363c
INFO Disassociated                                 id=rtbassoc-0111f5669e7a75461
INFO Disassociated                                 id=rtbassoc-075ae577b6d0ebcf1
INFO Deleted                                       id=india-xdxxn-openshift-image-registry-ncjg2 policy=india-xdxxn-openshift-image-registry-ncjg2-policy
INFO Deleted                                       id=india-xdxxn-openshift-image-registry-ncjg2
INFO Deleted                                       id=eni-0cf2ad56fede25065
INFO Deleted                                       id=india-xdxxn-openshift-cloud-network-config-contro-28x5v policy=india-xdxxn-openshift-cloud-network-config-contro-28x5v-policy
INFO Deleted                                       id=india-xdxxn-openshift-cloud-network-config-contro-28x5v
INFO Deleted                                       id=india-xdxxn-sint/9d682d2e77919661
INFO Deleted                                       id=eni-0b6deeaea26d32343
INFO Deleted                                       id=india-xdxxn-openshift-machine-api-aws-7b2tx policy=india-xdxxn-openshift-machine-api-aws-7b2tx-policy
INFO Deleted                                       id=india-xdxxn-openshift-machine-api-aws-7b2tx
INFO Deleted                                       id=Z081688721TABN9YZWO00 record set=A api-int.india.openshift.conygre.com.
INFO Deleted                                       id=Z081688721TABN9YZWO00 public zone=/hostedzone/Z00337721TI1DF77U2786 record set=A api.india.openshift.conygre.com.
INFO Deleted                                       id=Z081688721TABN9YZWO00 public zone=/hostedzone/Z00337721TI1DF77U2786 record set=A \052.apps.india.openshift.conygre.com.
INFO Deleted                                       id=vpce-09363e206c0b11e10
INFO Deleted                                       id=sg-0a1e043131e0f7fd2
INFO Deleted                                       id=nat-0c644c2dad367d7d2
INFO Deleted                                       id=sg-0bc65545cd5ec0c84
INFO Deleted                                       id=Z081688721TABN9YZWO00 record set=A api.india.openshift.conygre.com.
INFO Deleted                                       id=Z081688721TABN9YZWO00 record set=A \052.apps.india.openshift.conygre.com.
INFO Deleted                                       id=Z081688721TABN9YZWO00
INFO Released                                      id=eipalloc-044338408c183a6a6
INFO Deleted                                       NAT gateway=nat-0c644c2dad367d7d2 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0a85dbda115083743 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0fd2375e295c2a35b id=vpc-033b9645884e8df1e
INFO Deleted                                       id=vpc-033b9645884e8df1e network interface=eni-07276b02d418f05e3
INFO Deleted                                       id=subnet-087dc2a4bf296530d
INFO Deleted                                       id=sg-03fdae761e8a43b95
INFO Deleted                                       id=subnet-02019eb63ec31d49f
INFO Deleted                                       id=subnet-03e88eabc6b631146
INFO Deleted                                       NAT gateway=nat-0c644c2dad367d7d2 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0a85dbda115083743 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0fd2375e295c2a35b id=vpc-033b9645884e8df1e
INFO Deleted                                       id=subnet-0d6a21f764c0bde1a
INFO Deleted                                       NAT gateway=nat-0c644c2dad367d7d2 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0a85dbda115083743 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0fd2375e295c2a35b id=vpc-033b9645884e8df1e
INFO Deleted                                       id=subnet-0ea90dcb13ab25737
INFO Released                                      id=eipalloc-0420bc34fb4fa4760
INFO Released                                      id=eipalloc-0bf3d9d478a2d97b4
INFO Deleted                                       NAT gateway=nat-0c644c2dad367d7d2 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0a85dbda115083743 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0fd2375e295c2a35b id=vpc-033b9645884e8df1e
INFO Deleted                                       id=vpc-033b9645884e8df1e table=rtb-00da966d5b2cf97eb
INFO Deleted                                       id=vpc-033b9645884e8df1e subnet=subnet-07b71834459bf83f3
INFO Deleted                                       id=igw-0caf9682b0643df31
INFO Deleted                                       NAT gateway=nat-0c644c2dad367d7d2 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0a85dbda115083743 id=vpc-033b9645884e8df1e
INFO Deleted                                       NAT gateway=nat-0fd2375e295c2a35b id=vpc-033b9645884e8df1e
INFO Deleted                                       id=vpc-033b9645884e8df1e
INFO Deleted                                       id=dopt-058885408f1e4aa47
INFO Time elapsed: 6m32s
```

Started at 13:50
Finished at 13:59