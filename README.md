# OpenShift 4 Cluster Installation AWS

An easy installation for AWS OpenShift 4 cluster.

This repository shows;
- [Manual installation](ManualInstall.md)
- [Automated install](UsingAutomation.md)

Once your cluster is built you'll see in the output, or in the log file .openshift_install.log the URL and credentials for the kubeadmin.

After the **add-login** script has been executed you will have the following user;
- developer
- admin

With password of c0nygre.

You can then use the following from the command line to log in, once the cluster has added the config.

```
oc login https://api.${REGION}.openshift.conygre.com:6443 -u developer -p c0nygre
```

The web console should look as follows, once htpasswd has been configured;

![Web console with htpasswd](images/OpenShiftConsoleLogin.png)

Use the **classroom** to log on as **developer**