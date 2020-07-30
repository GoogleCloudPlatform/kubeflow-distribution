"""A simple script to recourse over a directory and rewrite files to an ACM repo.

ACM repos are structured a certain way. In particular cluster and namespace
resources need to be in different directories. This script takes as
an input a directory and rewrites all the resources into the target
directory.
"""

import argparse
import logging
import os
import re
import yaml

if __name__ == "__main__":
  logging.basicConfig(
      level=logging.INFO,
      format=('%(levelname)s|%(asctime)s'
              '|%(pathname)s|%(lineno)d| %(message)s'),
      datefmt='%Y-%m-%dT%H:%M:%S',
  )
  logging.getLogger().setLevel(logging.INFO)

  parser = argparse.ArgumentParser()

  parser.add_argument(
    "--source", default=os.getcwd(), type=str,
    help=("The path to recourse over looking for YAML files"))

  parser.add_argument(
    "--dest", default=os.getcwd(), type=str,
    help=("Root of the ACM repo to write to."))

  args = parser.parse_args()

  for root, _, files in os.walk(args.source):
    for f in files:
      _, ext = os.path.splitext(f)
      if not ext.lower() in [".yaml", ".yml"]:
        continue

      path = os.path.join(root, f)

      # Ensure annotations is a map. This is another error we are seeing
      with open(path) as hf:
        contents = yaml.load_all(hf)
        for o in contents:
          if not o:
            continue
          api_version = o.get("apiVersion")
          metadata = o.get("metadata")
          namespace = metadata.get("namespace")
          kind = o.get("kind")
          name  = metadata.get("name")
          filename = "_".join([api_version.replace("/", "_"),
                               kind,
                               name]) + ".yaml"

          if kind.lower() == "namespace":
            filename = "namespace.yaml"
            outdir = os.path.join(args.dest, "namespaces", name)
          elif not namespace:
            outdir = os.path.join(args.dest, "cluster",)
          else:
            outdir = os.path.join(args.dest, "namespaces", namespace)

          if not os.path.exists(outdir):
            os.makedirs(outdir)
            logging.info("Creating directory %s", outdir)

          with open(os.path.join(outdir, filename), "w") as hf:
            yaml.dump(o, hf)


