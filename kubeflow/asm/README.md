# Anthos Service Mesh (ASM)

[Anthos Service Mesh introduction](https://cloud.google.com/anthos/service-mesh)

## Upgrade ASM

### Documentations

* [Official guide to upgrade ASM](https://cloud.google.com/service-mesh/docs/upgrade-path-old-versions-gke)
* [Kubeflow guide to upgrade ASM](https://www.kubeflow.org/docs/distributions/gke/deploy/upgrade/#upgrade-asm-anthos-service-mes)
* [Official ASM instalation guide](https://cloud.google.com/service-mesh/docs/unified-install/install-anthos-service-mesh)
* [Integrate ASM with IAP](https://cloud.google.com/service-mesh/docs/unified-install/options/iap-integration)

### Upgrade steps for legacy ASM installation approach

You can upgrade ASM by first installing ASM tools' package, and installing new ASM to cluster. Migrate existing workload to new ASM, then deprecate the old ASM:

* Get a list of stable versions of `asmcli` and `config packages` by running this command:

    ```
    curl https://storage.googleapis.com/csm-artifacts/asm/ASMCLI_VERSIONS
    ```

    For example: `1.13.4-asm.4+config2:asmcli`. The part before colon symbol (1.13.4-asm.4+config2) should be used for `ASM_PACKAGE_VERSION` in Makefile of current directory. The part after colon symbol (asmcli) should be used for `ASMCLI_SCRIPT_VERSION`.

* Determine the ASM version you want to upgrade, follow the instruction above to update `ASM_PACKAGE_VERSION` and `ASMCLI_SCRIPT_VERSION` in Makefile. Then run the following command under `kubeflow/common/asm` to install new ASM version.

    ```
    make install-asm
    ```

* Update `kubeflow/env.sh` for the ASM version, this looks like format: **asm-1134-4**, and you can find the exact value in istiod pod's label as well.
    
    For example: You can find label `istio.io/rev: asm-1134-4` in istiod-asm-1134-4 service. Then run `source env.sh` under `kubeflow/` folder.

* Configure kpt setter value under `kubeflow/` for all Kubeflow components which require to set ASM namespace label:

    ```
    bash kpt-set.sh
    ```

* Follow official doc [Deploy and Redeploy workloads](https://cloud.google.com/service-mesh/docs/unified-install/upgrade#deploying_and_redeploying_workloads) to migrate workloads in each namespace, including user namespace created in [Kubeflow multi-tenancy](https://www.kubeflow.org/docs/components/multi-tenancy/getting-started/). In the case of Kubeflow cluster deployment, you can rerun `make apply` under `kubeflow/` directory to upgrade workloads. (Note: You can also run `make hydrate` before `make apply` to compare the difference of resource manifests.)

    ```
    make apply
    ```

* (Optional): Deprecate old ASM by following `Complete the transistion -> Migrate` in [Deploy and Redeploy workloads](https://cloud.google.com/service-mesh/docs/unified-install/upgrade#deploying_and_redeploying_workloads).
