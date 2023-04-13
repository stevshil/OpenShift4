# Automated

This method makes use of some shell scripts to build the cluster.

## Pre-requisites

1. IAM Role for Instance which give Administrator Access, instead of using Keys and Secrets
2. EC2 t2.micro instance with 12GB disk and SSH access
3. Copy the bin directory to the above EC2 instance

## Creating the IAM role

**NOTE** This is a one time creation for each region.

- Go to **IAM/Roles**
- Click **Create role**
- Select **AWS Service**
- Under **Use case** select **EC2**
- Click **Next**
- In the **Permissions policies** type **Administrator** and press **Enter**
- Select **AdministratorAccess** with the tickbox
- Click **Next**
- **Role Name** call it **OpenShift4Install**
- Click **Add tag** button and type **Name** for Key and **OpenShift 4 Role** for value
- Click **Create role**

## Creating the EC2 instance

Here you should follow your normal method for launching an EC2 instance (you may already have this machine available as an AMI).

- Click **Launch instance**
- Set your tags
- Leave AMI as AWS
- Leave Instance type as t2.micro
- Select your Key pair that you have to be able to log on
- Select an existing security group with SSH or if there is none create one
- Configure storage change size to **20**
- Expand **Advanced details**
- In the **IAM instance profile** click the pull down and select your **OpenShift4Install** IAM role
- Click **Launch instance**

## Copy bin directory to EC2 instance

- Grab the public IP address of the instance you have just created.
- Then using SCP copy this **bin** directory to the server
    ```
    scp -ri YourAWSPrivateSSHKey bin ec2-user@YourInstancePublicIP:
    ```

## Creating the cluster

### Setting up requirements

**IMPORTANT:** You need to modify the **bin/setup.sh** script and the **bin/new-cluster** and change the **pullSecret:** value to a valid Red Hat OpenShift pull secret.  You can obtain one from the Install OpenShift with the Assisted Installer - https://console.redhat.com/openshift/assisted-installer/clusters/~new
- Scroll down the page to **Edit pull secret**
- Tick the box
- Copy the text from the box (this is your pull secret)

In the [**bin**](bin) directory is a file called [**env**](bin/env).  You should modify this file to suit your cluster configuration and AWS region.

### Create the cluster

To build the cluster you can now run the **bin/setup.sh** command.

This command will detach from the main process as it can take some time and your terminal may time out.

Don't panic, as the script runs a **tail** on the nohup.out file.

If you lose connection simply log back on and run;
```
tail /openshift/nohup.out
```

The script provides output on what to do and when the cluster is successfully completed.

## Other scripts

There are other scripts in the **bin** directory which allow you to;

- Destroy the cluster
  - **NOTE** you should never delete the **/openshift** and its subdirectories unless the cluster has been **destroyed**.  The reason for this is that the state of the cluster is stored there.
  - To destroy the cluster run
        ```
        bin/delete-cluster
        ```
- Building a new cluster
  - If you have launched an AMI of a server with this already installed, then you should run the ```bin/new-cluster.sh``` script.


# Troubleshooting

The cluster can take a while to install.  If it fails it will normally fail at the **master** control plane stage.  You may have to wait about an hour from initially start before this happens.  Let the command exit, do not kill it.

Once the log has reported failure you can run the **bin/delete-cluster** command to clean up.

**NOTE** when deleting the cluster it will delete everything, so use the **bin/new-cluster.sh** command to build a new one after you've made modifications to the **env** file and possibly the **/openshift/install-config.yaml** file.