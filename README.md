# Toolkit Docker E2E Playground

[Security](./SECURITY.md) · [Reporting policy](./CONTRIBUTING.md)

This repository is the end-to-end consumer project for the Grootan GitHub CI
library's Docker pipeline. It carries a reviewable snapshot of the toolkit
`Dockerfile` and its image smoke test, builds and scans candidate images, then
promotes the verified digest to Docker Hub as `grootantech/toolkit:<version>`.

## Included E2E files

| File | Purpose |
|---|---|
| [`Dockerfile`](./Dockerfile) | Builds the complete toolkit image. |
| [`ci_image_test.sh`](./ci_image_test.sh) | Verifies every required tool inside the resulting image. |
| [`.github/workflows/pr.yml`](./.github/workflows/pr.yml) | Builds, tests, scans, and guards candidate images. |
| [`.github/workflows/release.yml`](./.github/workflows/release.yml) | Promotes the verified candidate and publishes release notes. |
| [`.github/workflows/build.yml`](./.github/workflows/build.yml) | Manually builds, publishes, and smoke-tests a candidate image. |
| [`.github/workflows/lint.yml`](./.github/workflows/lint.yml) | Runs the reusable Dockerfile, YAML, and changelog linters. |
| [`.github/workflows/check.yml`](./.github/workflows/check.yml) | Runs release prerequisites without building an image. |
| [`.github/workflows/image-scan.yml`](./.github/workflows/image-scan.yml) | Scans any published toolkit image tag. |
| [`.github/workflows/secret-scan.yml`](./.github/workflows/secret-scan.yml) | Scans the complete Git history for exposed secrets. |
| [`CHANGELOG.md`](./CHANGELOG.md) | Initial `1.0.0` release notes. |

## Image contents

Every tool version is pinned as an `ARG` in [`Dockerfile`](./Dockerfile) and
bumped by Renovate, so the Dockerfile — not this list — is the source of truth
for versions.

### Language runtimes & package managers

| Tool | Notes |
|---|---|
| Go | `/usr/local/go`, `GOPATH=/go` |
| Java (Eclipse Temurin JDK) | `JAVA_HOME=/usr/local/java` |
| Maven | `MAVEN_HOME=/usr/local/maven` |
| Node.js | `NODE_HOME=/usr/local/node` |
| npm | with `npx` and `corepack` |
| Yarn | |
| Python | `python` / `python3` symlinked |
| uv | installs the Python libraries below |

### Infrastructure as code

Terraform, OpenTofu, TFLint, terraform-docs, Ansible, ansible-lint

### Kubernetes & Helm

Helm (with the `helm-unittest` plugin, `HELM_DATA_HOME=/usr/local/share/helm`),
helm-docs, kubectl, Argo CD CLI

### Containers & registries

Docker CLI, Docker Buildx plugin, Buildah, Podman, crane
(go-containerregistry)

### Security & supply chain

Trivy, betterleaks, gosec

### Linters & formatters

hadolint, actionlint, ShellCheck, golangci-lint, Biome, yamllint, ruff, mypy,
pycodestyle, isort

### Code generation & release

swag (Swagger for Go), GitLab `release-cli`

### Python libraries (installed with `uv pip`)

`requests`, `Jinja2`, `ansible`, `ansible-lint`, `jmespath`,
`semantic-version`, `botocore`, `boto3`, `yamllint`, `pycodestyle`, `isort`,
`mypy`, `ruff`

### Base OS packages

`git`, `curl`, `wget`, `jq`, `yq`, `tar`, `zip`, `unzip`, `gzip`, `xz`,
`make`, `which`, `findutils`, `diffutils`, `patch`, `less`, `openssl`,
`openssh-clients`, `sshpass`, `rsync`, `s-nail`, `yum-utils`

### Base image

The build is multi-stage. Tools are downloaded and unpacked in a builder stage,
with `release-cli` and the Buildx plugin pulled from their own upstream images,
then copied into the final stage. The final stage — the image that is published
as `grootantech/toolkit:<version>` — is `redhat/ubi9-minimal`, pinned by digest
tag via the `BASE_IMAGE_TAG` build argument.

## GitHub repository configuration

Configure these Actions variables:

| Variable | Value |
|---|---|
| `IMAGE_REGISTRY` | `registry-1.docker.io` |
| `IMAGE_REPOSITORY` | `grootantech/toolkit` |

This Docker-only project deliberately disables the shared migration guard. Its
compatibility surface is the published OCI image and the smoke-test contract.

Configure these Actions secrets:

| Secret | Purpose |
|---|---|
| `IMAGE_REGISTRY_USERNAME` | Docker Hub account or organization service account. |
| `IMAGE_REGISTRY_PASSWORD` | Docker Hub access token with permission to push `grootantech/toolkit`. |

## License

Copyright 2026 Grootan Technologies Pvt Ltd.

Release notes over 125,000 characters are truncated in the GitHub Release body and
attached in full as an asset.

Releases are cut by a push to `main` that touches something outside `.github/**`;
the pipeline promotes the image the pull request already built rather than
rebuilding it. A workflow-only change therefore never releases. Bump `VERSION`
and add a `CHANGELOG.md` entry in the same pull request — the release guards
refuse a version that is already tagged. See `.github/workflows/release.yml`.

Licensed under the [GNU Affero General Public License v3.0](./LICENSE.md)
(`AGPL-3.0-only`). External contributions are not accepted; see
[CONTRIBUTING.md](./CONTRIBUTING.md) for bug and security reporting.
