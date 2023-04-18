# Automated

This method makes use of some shell scripts to build the cluster.

## Pre-requisites

1. $HOME/.aws/config and $HOME/.aws/credentials

## Creating the AWS credentials

The script will prompt you to set up the AWS config and credentials if the $HOME/.aws/credentials file does not exist.

## Doing it yourself

### Using the command line

Either run the command ```aws configure``` and answer the questions
  - region = The region you are creating the cluster in, e.g. ap-south-1
  - output = json
  - aws access key = The access key you have been provided
  - aws secret key = The secret key you have been provided, this is the longer of the 2

### Alternatively creating the files

**The config file**

```
cat >$HOME/.aws/config <<_EOF
[default]
region = ap-south-1
output = json
_EOF
```

**The credentials file**

```
cat >$HOME/.aws/credentials <<_EOF
[default]
aws_access_key_id = **************
aws_secret_access_key = ****************
_EOF
```

Replace the ************* with your values

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

**IMPORTANT:** In the [**bin**](bin) directory is a file called [**env**](bin/env).  You should modify this file to suit your cluster configuration and AWS region.

### Create the cluster

To build the cluster you can now run the **create-cluster** command.  The $HOME/bin directory is in your users path.

This command will detach from the main process as it can take some time and your terminal may time out.

Don't panic, as the script runs a **tail** on the nohup.out file.

If you lose connection simply log back on and run;
```
tail $HOME/openshift/nohup.out
```

The script provides output on what to do and when the cluster is successfully completed.

## Other scripts

There are other scripts in the **bin** directory which allow you to;

- Destroy the cluster
  - **NOTE** you should never delete the **/openshift** and its subdirectories unless the cluster has been **destroyed**.  The reason for this is that the state of the cluster is stored there.
  - To destroy the cluster run
        ```
        delete-cluster
        ```
  - Shutting down the cluster
    ```
    shutdown-cluster 10
    ```

### Building a new cluster

The **create-cluster** script can be used to build a new cluster.  You will need to:
- Remove the old cluster with the **delete-cluster** command
- Remove $HOME/openshift
- Run **create-cluster**


# Troubleshooting

The cluster can take a while to install.  If it fails it will normally fail at the **master** control plane stage.  You may have to wait about an hour from initially start before this happens.  Let the command exit, do not kill it as it might still be taking a while.

Once the log has reported failure you can run the **delete-cluster** command to clean up.