# Automated

This method makes use of some shell scripts to build the cluster.

## Pre-requisites

Before you begin you should check that your AWS account has a user called **OpenShiftAdmin**.  If not create this user and also create the Security credentials **Access Key**.

**NOTE:** The user does not need console access, and the key should be for the CLI.

You should create 2 **Parameter Store** keys that will contain the **Access Key** values.  This can be done as follows;

- In the **Search** text box next to **Services** type in **Parameter Store** and click **Parameter Store**
- Click **Create parameter** button
- For the Access ID
  - Enter the name **/OpenShiftAdmin/AccessId**
  - Leave as **Standard**
  - Leave Type as **String**
  - Leave Data type as **Text**
  - In **Value** paste in your Access Id from the Access Key.
  - Click **Create parameter**
- For the Secret Key
  - Enter the name **/OpenShiftAdmin/Secret**
  - Leave as **Standard**
  - Change Type to **SecureString**
  - KMS key store leave as **My current account**
  - Leave KMS Key ID as is
  - In the **Value** paste in your Secret Key from the Access Key.

## Create the Instance Role

This will be the role that is required by the EC2 Instance to access elements of AWS as an Administrator.

If the role **OpenShiftAdmin** does not exist in your AWS system then run the **[create-role](bin/create-role)** script, or manually create the role as an Instance role.

### Creating the IAM role manually

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
- In the **IAM instance profile** click the pull down and select your **OpenShiftAdmin** IAM role
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
    shutdown-cluster
    ```
    This will default to 12 hour shutdown period (the number of hours is something openshift needs).

    To change the number of hours the cluster will be down add the number as a parameter;
    ```
    shutdown-cluster 5
    ```

### Building a new cluster

The **create-cluster** script can be used to build a new cluster.  You will need to:
- Remove the old cluster with the **delete-cluster** command
- Remove $HOME/openshift
- Run **create-cluster**


# Troubleshooting

The cluster can take a while to install.  If it fails it will normally fail at the **master** control plane stage.  You may have to wait about an hour from initially start before this happens.  Let the command exit, do not kill it as it might still be taking a while.

Once the log has reported failure you can run the **delete-cluster** command to clean up.