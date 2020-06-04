# Deploy Kubeflow with Private GKE

These instructions explain how to deploy Kubeflow using private GKE and VPC-SC.

1. Follow the blueprint instructions to setup a management cluster

1. As a work around for (kubeflow/gcp-blueprints#32)[https://github.com/kubeflow/gcp-blueprints/issues/32]
   modify the containercluster CRD schema in your management cluster to include missing fields

   * See directions in that issue.

1. Fetch the blueprint

   ```
   kpt pkg get https://github.com/kubeflow/gcp-blueprints.git/kubeflow@master ./${PKGDIR}
   ```

1. Change to the kubeflow directory

   ```
   cd ${PKGDIR}
   ```

1. Fetch Kubeflow manifests

   ```
   make get-pkg
   ```

1. Add the private GKE patches to your kustomization

   1. Open `instance/gcp_config`
   1. In patchesStrategicMerge add 

      ```
      - ../../upstream/manifests/gcp/v2/privateGKE/cluster-private-patch.yaml
      ```

   1. In resources add

   	  ```
   	  - ../../upstream/manifests/gcp/v2/privateGKE/
   	  ```


   * Do not use `kustomize edit` to perform the above actions until [kubernetes-sigs/kustomize#2310](https://github.com/kubernetes-sigs/kustomize/issues/2310) is fixed

1. Open the `Makefile` and edit the `set-values` rule to invoke `kpt cfg set` with the desired values for
   your deployment

   * Change `kpt cfg set ./instance gke.private false` to `kpt cfg set ./instance gke.private true`
   * You need to set region, location and zone because the deployment is a mix of zonal and regional resources and some which could be either

### Deploy Kubeflow


1. Configure the setters

   ```
   make set-values
   ```

1. Set environment variables with OAuth Client ID and Secret for IAP

   ```
   export CLIENT_ID=
   export CLIENT_SECRET=
   ```

1. Deploy Kubeflow

   ```
   make apply
   ```

   * If this times out waiting for the cluster to be ready check if the reason the update failed is
     because of [kubeflow/gcp-blueprints#34](https://github.com/kubeflow/gcp-blueprints/issues/35)

   * In this case you can simply edit the Makefile and comment out the line

     ```     
	 kubectl --context=$(MGMTCTXT) wait --for=condition=Ready --timeout=600s  containercluster $(NAME)
     ```

   * Then rerun `make apply`

1. TODO(jlewi): Add instructions for how to run the go binary locally to create the DNS endpoint
   because the controller won't work.



## Architectural notes

* The reference architecture uses [Cloud Nat](https://cloud.google.com/nat/docs/overview) to allow outbound
  internet access from node even though they don't have public IPs.

  * Outbound traffic can be restricted using firewall rules

  * Outbound internet access is needed to download the JWKs keys used to verify JWTs attached by IAP

  * If you want to completely disable all outbound internet access you will have to find some alternative solution
    to keep the JWKs in sync with your ISTIO policy


## Troubleshooting

* Cluster is stuck in provisioning state

  * Use the UI or gcloud to figure out what state the cluster is stuck in
  * If you use gcloud you need to look at the operation e.g.

    
    1. Find the operations
    
       ```
       gcloud --project=${PROJECT} container operations list
       ```

    1. Get operation details

	   ```
       gcloud --project=${PROJECT} container operations describe --region=${REGION} ${OPERATION}
       ```

* Cluster health checks are failing.

   * This is usually because the firewall rules allowing the GKE health checks are not configured correctly

   * A good place to start is verifying they were created correctly

     ```
     kubectl --context=${MGMTCTXT} describe computefirewall
     ```

   * Turn on firewall rule logging to see what traffic is being blocked

     ```
     kpt cfg set ./upstream/manifests/gcp/v2/privateGKE/ log-firewalls true
     make apply
     ```

   * To look for traffic blocked by firewall rules in stackdriver use a filter like the following

      ```

	  logName: "projects/${PROJECT}/logs/compute.googleapis.com%2Ffirewall" 
 	  jsonPayload.disposition = "DENIED"
      ```

      * **Logging must be enabled** on your firewall rules. You can enable it by using a kpt setter

        ```
        kpt cfg set ./upstream/manifests/gcp/v2/privateGKE/ log-firewalls true 
        ```

      * Change project to your project

      * Then look at the fields `jsonPayload.connection` this will tell you source and destination ips
      * Based on the IPs try to figure out where the traffic is coming from (e.g. node to master) and
        then match to appropriate firewall rules

      * For example

         ```
          connection: {
		   dest_ip: "172.16.0.34"    
		   dest_port: 443    
		   protocol: 6    
		   src_ip: "10.10.10.31"    
		   src_port: 60556    
		  }
		  disposition: "DENIED" 
         ```

         * The destination IP in this case is for a GKE master so the firewall rules are not configured to correctly allow
           traffic to the master.


* Common cause for networking related issue is is that some of the network resources (e.g. the Network, Routes, Firewall Rules, etc... ) don't get created

     * This could be because a reference is incorrect (e.g. firewall rules reference the wrong network)

     * You can sanity check resources by doing kubectl describe and looking for errors.

       * [kubeflow/gcp-blueprints#38](https://github.com/kubeflow/gcp-blueprints/issues/38) is tracking
          tools to automate this

* GCR images can't be pulled

  * This likely indicates an issue with access to private GCR; this could be an issue with

    * DNS configurations - Check that the `DNSRecordSet` and `DNSManagedZone` CNRM resources are in a ready state
    * Routes - Ensure any default route to the internet has a larger value for the priority 
        then any routes to private GCP APIs so that the private routes match first.

        * If image pull errors show IP addresses not the restricted.googleapis.com VIP then you have
          an issue with networking

    * Firewall rules

* Access to whitelisted (non Google) sites is blocked

  * The configuration uses CloudNat to allow selective access to sites

    * In addition to allowing IAP, this allows sites like GitHub to be whitelisted.

  * In order for CloudNat to work you need

    * A default route to the internet
    * Firewall rules to allow egress traffic to whitelisted sites

      * These rules need to be higher priority then the deny all firewall egress rules.

### Kubernetes Webhooks are blocked by firewall rules

A common failure mode is that webhooks for custom resources are blocked by default firewall rules.
As explained in the [GKE Docs](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#add_firewall_rules) only connections from master to ports 443 and 10250
are allowed by default. If you have a webhook serving on a different port
you will need to add an explict ingress firewall rule to allow that port to be accessed.

These errors usually manifest as failures to create custom resources that depend on webhooks. An example
error is

```
Error from server (InternalError): error when creating ".build/kubeflow-apps/cert-manager.io_v1alpha2_certificate_admission-webhook-cert.yaml": Internal error occurred: failed calling webhook "webhook.cert-manager.io": the server is currently unable to handle the request
```

# References

[Blog Post Private GKE Clusters](https://medium.com/google-cloud/completely-private-gke-clusters-with-no-internet-connectivity-945fffae1ccd)