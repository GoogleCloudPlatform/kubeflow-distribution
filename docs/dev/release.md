# Release Instructions

## Pin a tag

- Choose a tag name and a release branch:
  ```bash
  export TAG_NAME=v1.2.0
  export BRANCH=master
  ```

- Pin the following to ${TAG_NAME} commit and push to release branch
  * https://github.com/kubeflow/gcp-blueprints/blob/7ee2cf6599695e7337382af83969de431a052677/management/Makefile#L12
  * https://github.com/kubeflow/gcp-blueprints/blob/7ee2cf6599695e7337382af83969de431a052677/kubeflow/Makefile#L28

- Add a new tag and push it to upstream release branch
  ```bash
  git checkout ${BRANCH}
  git pull
  git tag -a "${TAG_NAME}" -m "Kubeflow on Google Cloud ${TAG_NAME} release"
  git push upstream v1.2.0
  ```
