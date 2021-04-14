"""This is a script created for the updating of the GCP Kpt packages.

The purpose of this is to upgrade to using setters and substitutions
"""

import fire
import logging
import os
import re
import subprocess

def create_setter(name, value, cwd, field=None):
  command = ["kpt", "cfg", "create-setter", ".", name, value]

  if field:
    command.append("--field")
    command.append(field)

  logging.info("Run:\n" + " ".join(command))
  subprocess.check_call(command,  cwd=cwd)

def create_subst(name, value, pattern, cwd):
  command = ["kpt", "cfg", "create-subst", ".",  name,
             "--field-value", value,
             "--pattern", pattern]
  logging.info("Run:\n" + " ".join(command))
  subprocess.check_call(command,  cwd=cwd)

class KptCreator:
  @staticmethod
  def strip_comments(path):
    """Strip the existing comments from YAML files"""

    for root, _, files in os.walk(path):
      for f in files:
        ext = os.path.splitext(f)[-1]
        logging.info(f"{ext}")
        if ext != ".yaml":
          continue

        p = os.path.join(root, f)
        logging.info(f"Proccessing {p}")

        with open(p) as hf:
          lines = hf.readlines()

        new_lines = []

        for l in lines:
          if re.match("[^#]+#.*x-kustomize.*", l):
            pieces = l.split("#", 1)
            new_lines.append(pieces[0].rstrip() + "\n")
          else:
            new_lines.append(l)

        with open(p, "w") as hf:
          hf.writelines(new_lines)


  @staticmethod
  def create_subst(path):

    create_setter("kustomize_manifests_path", "../../../upstream/manifests", path)
    create_setter("gcloud.core.project", "PROJECT", path)

    create_subst("ip-name", "KUBEFLOW-NAME-ip", "${name}-ip", path)

    create_subst("storage-artifact-store-name",
                 "KUBEFLOW-NAME-storage-artifact-store",
                 "${name}-storage-artifact-store", path)

    create_subst("metadata-artifact-store-name",
                 "KUBEFLOW-NAME-storage-metadata-store",
                 "${name}-storage-metadata-store", path)

    create_subst("hostname", "KUBEFLOW-NAME.endpoints.PROJECT.cloud.goog",
                 "${name}.endpoints.${gcloud.core.project}.cloud.goog", path)

    create_subst("gcp-sa",
                 "KUBEFLOW-NAME-user@PROJECT.iam.gserviceaccount.com",
                 "${name}-user@${gcloud.core.project}.iam.gserviceaccount.com",
                 path)

    create_subst("gcp-sa-admin",
                 "KUBEFLOW-NAME-admin@PROJECT.iam.gserviceaccount.com",
                 "${name}-admin@${gcloud.core.project}.iam.gserviceaccount.com",
                 path)

    paths = ["knative/installs/generic", "gcp/iap-ingress/v3", "namespaces/base",
             "istio/iap-gateway/base", "metacontroller/base",
             "cert-manager/cert-manager-kube-system-resources/base",
             "cert-manager/cert-manager/v3",
             "istio/istio/base",
             "application/v3",
             "stacks/gcp",
             "gcp/cloud-endpoints/overlays/application",
             "cert-manager/cert-manager-cdrds/base",
             "cert-manager/cert-manager/kubeflow-issuer"]

    for p in paths:
      name = p.replace("/", "-")
      value = os.path.join("../../../upstream/manifests", p)
      pattern = f"${{kustomize_manifests_path}}/{p}"
      create_subst(name, value, pattern, path)

if __name__ == "__main__":
  logging.basicConfig(
      level=logging.INFO,
      format=('%(levelname)s|%(asctime)s'
              '|%(pathname)s|%(lineno)d| %(message)s'),
      datefmt='%Y-%m-%dT%H:%M:%S',
  )
  logging.getLogger().setLevel(logging.INFO)
  fire.Fire(KptCreator)
