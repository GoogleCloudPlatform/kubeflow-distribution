# End to end testing for management cluster setup

1. Edit `Makefile`'s variables at the top.
2. Edit `storagebucket.yaml`'s name and namespace (namespace means GCP project).
3. Run the e2e user install steps
    ```bash
    make test
    ```
4. Clean up all the resources created
    ```bash
    make cleanup
    ```
