# Overlays

* This directory defines [overlays](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#overlay) of the vendored packages that customize
  Kubeflow for your particular use case

* These customizations are stored as overlays("patches") ontop of the vendored
  packages to make it easy to upgrade the vendored packages while
  preserving your modfications.
