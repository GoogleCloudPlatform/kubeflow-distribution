# Anthos Service Mesh (ASM)

Introduction to ASM: [Anthos Service Mesh](https://cloud.google.com/anthos/service-mesh)

## Upgrade ASM

### Reference guidelines

* [Official guide to upgrade ASM](https://cloud.google.com/service-mesh/docs/upgrade-path-old-versions-gke)
* [Kubeflow guide to upgrade ASM](https://www.kubeflow.org/docs/distributions/gke/deploy/upgrade/#upgrade-asm-anthos-service-mes)
* [Official ASM installation guide](https://cloud.google.com/service-mesh/docs/unified-install/install-anthos-service-mesh)
* [Integrate ASM with IAP](https://cloud.google.com/service-mesh/docs/unified-install/options/iap-integration)

### Upgrade steps

The following steps explain how to install a newer version of ASM, migrate Kubeflow's workloads, and deprecate the old ASM or revert the new ASM.

1. Get a list of stable versions of `config packages` and `asmcli` by running this command:

    ```
    curl https://storage.googleapis.com/csm-artifacts/asm/ASMCLI_VERSIONS
    ```
    
    It should return a list of ASM versions that can be installed with `asmcli` tool. To install older versions, refer to [legacy instructions](deprecated/README.md). The returned list will have a format of `ASM_PACKAGE_VERSION:ASMCLI_SCRIPT_VERSION`. For example, in the following output:

    ```
    ...
    1.13.2-asm.5+config2:asmcli_1.13.2-asm.5-config2
    1.13.2-asm.5+config1:asmcli_1.13.2-asm.5-config1
    1.13.2-asm.2+config2:asmcli_1.13.2-asm.2-config2
    1.13.2-asm.2+config1:asmcli_1.13.2-asm.2-config1
    1.13.1-asm.1+config1:asmcli_1.13.1-asm.1-config1
    ...
    ```

    record `1.13.2-asm.5+config2:asmcli_1.13.2-asm.5-config2` corresponds to:

    ```
    ASM_PACKAGE_VERSION=1.13.2-asm.5+config2
    ASMCLI_SCRIPT_VERSION=asmcli_1.13.2-asm.5-config2
    ```
    
    You need to set these variable in the [Makefile](./Makefile) inside **`kubeflow/asm/`** directory.

2. After updating `ASM_PACKAGE_VERSION` and `ASMCLI_SCRIPT_VERSION` variables in the [Makefile](./Makefile), run the following command in **`kubeflow/asm/`** directory to install the chosen new ASM version:

    ```
    make install-asm
    ```

3. Update `ASM_LABEL` variable in **[env.sh](../env.sh)** located in **`kubeflow/`** directory. For example, it takes value of **asm-1132-5** for ASM version 1.13.2-asm.5. 

    You can also find this value in istiod pod's label: `istio.io/rev: asm-1132-5` in istiod-asm-1132-5 service. 
    
    Then run the following command in **`kubeflow/`** directory:

    ```
    source env.sh
    ``` 

4. Configure kpt setter values for all Kubeflow components that require new ASM namespace label by running the following command in **`kubeflow/`** directory:

    ```
    bash kpt-set.sh
    ```

5. Follow the official instructions on how to [deploy and redeploy workloads](https://cloud.google.com/service-mesh/docs/unified-install/upgrade#deploying_and_redeploying_workloads) to migrate them to a new ASM in each namespace, including user namespace created in [Kubeflow multi-tenancy](https://www.kubeflow.org/docs/components/multi-tenancy/getting-started/). In case of Kubeflow cluster deployment, you can rerun the following command in **`kubeflow/`** directory:

    ```
    make apply
    ```

    > **Note:**
    > you can also run `make hydrate` before `make apply` to compare the differences of the resource manifests.

6. (Optional): **Complete the transition** to the new ASM or **Rollback** to the old ASM as instructed in [Deploy and Redeploy workloads](https://cloud.google.com/service-mesh/docs/unified-install/upgrade#deploying_and_redeploying_workloads).
