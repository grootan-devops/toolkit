# renovate: datasource=docker depName=redhat/ubi9-minimal versioning=redhat
ARG BASE_IMAGE_TAG=9.8-1790074235

# renovate: datasource=docker depName=python
ARG PYTHON_VERSION=3.12
# renovate: datasource=docker depName=registry.gitlab.com/gitlab-org/release-cli
ARG RELEASE_IMAGE_TAG=0.24.0
# renovate: datasource=github-releases depName=mikefarah/yq extractVersion=^v?(?<version>.+)$
ARG YQ_VERSION=4.53.6
# renovate: datasource=github-releases depName=hadolint/hadolint extractVersion=^v?(?<version>.+)$
ARG HADOLINT_VERSION=2.15.1
# renovate: datasource=docker depName=docker/buildx extractVersion=^v?(?<version>.+)$
ARG BUILDX_VERSION=0.37.1
# renovate: datasource=github-releases depName=aquasecurity/trivy extractVersion=^v?(?<version>.+)$
ARG TRIVY_VERSION=0.74.0
# renovate: datasource=github-releases depName=helm/helm extractVersion=^v?(?<version>.+)$
ARG HELM_VERSION=4.3.0
# renovate: datasource=github-releases depName=terraform-linters/tflint extractVersion=^v?(?<version>.+)$
ARG TFLINT_VERSION=0.64.0
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs extractVersion=^v?(?<version>.+)$
ARG TF_DOCS_VERSION=0.24.0
# renovate: datasource=github-releases depName=norwoodj/helm-docs extractVersion=^v?(?<version>.+)$
ARG HELM_DOCS_VERSION=1.14.2
# renovate: datasource=github-releases depName=betterleaks/betterleaks extractVersion=^v?(?<version>.+)$
ARG BETTERLEAKS_VERSION=1.8.1
# renovate: datasource=github-releases depName=google/go-containerregistry extractVersion=^v?(?<version>.+)$
ARG CRANE_VERSION=0.22.1
# renovate: datasource=npm depName=@biomejs/biome
ARG BIOME_CLI_VERSION=2.5.14
# renovate: datasource=github-releases depName=rhysd/actionlint extractVersion=^v?(?<version>.+)$
ARG ACTIONLINT_VERSION=1.7.12
# renovate: datasource=github-releases depName=koalaman/shellcheck extractVersion=^v?(?<version>.+)$
ARG SHELLCHECK_VERSION=0.11.0
# renovate: datasource=github-releases depName=helm-unittest/helm-unittest extractVersion=^v?(?<version>.+)$
ARG HELM_UNITTEST_VERSION=1.1.2
# renovate: datasource=github-tags depName=golang/go extractVersion=^go(?<version>.+)$
ARG GO_VERSION=1.27.1
# renovate: datasource=github-releases depName=swaggo/swag extractVersion=^v?(?<version>.+)$
ARG SWAG_VERSION=1.16.6
# renovate: datasource=github-releases depName=securego/gosec extractVersion=^v?(?<version>.+)$
ARG GOSEC_VERSION=2.29.0
# renovate: datasource=github-releases depName=golangci/golangci-lint extractVersion=^v?(?<version>.+)$
ARG GOLANGCI_LINT_VERSION=2.14.0
# renovate: datasource=github-releases depName=hashicorp/terraform extractVersion=^v?(?<version>.+)$
ARG TERRAFORM_VERSION=1.16.4
# renovate: datasource=github-releases depName=opentofu/opentofu extractVersion=^v?(?<version>.+)$
ARG TOFU_VERSION=1.12.6
# renovate: datasource=github-releases depName=adoptium/temurin25-binaries extractVersion=^jdk-(?<version>.+)$
ARG JAVA_VERSION=25.0.4.1+1
# renovate: datasource=github-releases depName=apache/maven extractVersion=^maven-(?<version>.+)$
ARG MAVEN_VERSION=3.9.16
# renovate: datasource=github-releases depName=astral-sh/uv extractVersion=^v?(?<version>.+)$
ARG UV_VERSION=0.12.19
# renovate: datasource=github-tags depName=nodejs/node extractVersion=^v?(?<version>.+)$
ARG NODE_VERSION=26.10.0
# renovate: datasource=npm depName=npm
ARG NPM_VERSION=12.1.0
# renovate: datasource=npm depName=yarn
ARG YARN_VERSION=1.22.22

FROM registry.gitlab.com/gitlab-org/release-cli:v${RELEASE_IMAGE_TAG} AS registry

FROM docker/buildx-bin:${BUILDX_VERSION} AS buildx

FROM redhat/ubi9-minimal:${BASE_IMAGE_TAG} AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG YQ_VERSION
ARG HADOLINT_VERSION
ARG HELM_VERSION
ARG TFLINT_VERSION
ARG TF_DOCS_VERSION
ARG HELM_DOCS_VERSION
ARG BIOME_CLI_VERSION
ARG BETTERLEAKS_VERSION
ARG CRANE_VERSION
ARG ACTIONLINT_VERSION
ARG SHELLCHECK_VERSION
ARG GO_VERSION
ARG SWAG_VERSION
ARG GOSEC_VERSION
ARG GOLANGCI_LINT_VERSION
ARG TERRAFORM_VERSION
ARG TOFU_VERSION
ARG JAVA_VERSION
ARG MAVEN_VERSION
ARG UV_VERSION
ARG NODE_VERSION
ARG NPM_VERSION
ARG YARN_VERSION

# hadolint ignore=DL3041
RUN microdnf update -y && \
    microdnf --nodocs --setopt install_weak_deps=0 install -y zip unzip gzip git tar openssl xz && \
    microdnf clean all

WORKDIR /tmp

RUN curl -fsSL "https://github.com/betterleaks/betterleaks/releases/download/v${BETTERLEAKS_VERSION}/betterleaks_${BETTERLEAKS_VERSION}_linux_x64.tar.gz" -o betterleaks.tar.gz & \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o go.tar.gz & \
    curl -fsSL "https://github.com/swaggo/swag/releases/download/v${SWAG_VERSION}/swag_${SWAG_VERSION}_Linux_x86_64.tar.gz" -o swag.tar.gz & \
    curl -fsSL "https://github.com/adoptium/temurin25-binaries/releases/download/jdk-${JAVA_VERSION}/OpenJDK25U-jdk_x64_linux_hotspot_${JAVA_VERSION%%+*}_${JAVA_VERSION##*+}.tar.gz" -o openjdk.tar.gz & \
    curl -fsSL "https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o maven.tar.gz & \
    curl -fsSL "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz" -o uv.tar.gz & \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" -o node.tar.gz & \
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -o helm.tar.gz & \
    curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o kubectl & \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" -o yq & \
    curl -fsSL "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-linux-x86_64" -o hadolint & \
    curl -fsSL "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64" -o argocd & \
    curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" -o tflint.zip & \
    curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TF_DOCS_VERSION}/terraform-docs-v${TF_DOCS_VERSION}-linux-amd64.tar.gz" -o tf-docs.tar.gz & \
    curl -fsSL "https://github.com/norwoodj/helm-docs/releases/download/v${HELM_DOCS_VERSION}/helm-docs_${HELM_DOCS_VERSION}_Linux_x86_64.tar.gz" -o helm-docs.tar.gz & \
    curl -fsSL "https://github.com/biomejs/biome/releases/download/%40biomejs%2Fbiome%40${BIOME_CLI_VERSION}/biome-linux-x64" -o biome & \
    curl -fsSL "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz" -o go-containerregistry.tar.gz & \
    curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" -o actionlint.tar.gz & \
    curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.gz" -o shellcheck.tar.gz & \
    curl -fsSL "https://github.com/securego/gosec/releases/download/v${GOSEC_VERSION}/gosec_${GOSEC_VERSION}_linux_amd64.tar.gz" -o gosec.tar.gz & \
    curl -fsSL "https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64.tar.gz" -o golangci-lint.tar.gz & \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o terraform.zip & \
    curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_amd64.tar.gz" -o tofu.tar.gz & \
    wait && \
    for f in betterleaks.tar.gz go.tar.gz swag.tar.gz openjdk.tar.gz maven.tar.gz uv.tar.gz node.tar.gz helm.tar.gz kubectl yq hadolint argocd tflint.zip tf-docs.tar.gz helm-docs.tar.gz biome go-containerregistry.tar.gz actionlint.tar.gz shellcheck.tar.gz gosec.tar.gz golangci-lint.tar.gz terraform.zip tofu.tar.gz; do \
        [ -s "$f" ] || { echo "Download failed for $f" >&2; exit 1; }; \
    done && \
    mkdir -p /usr/local/go /usr/local/java /usr/local/maven /usr/local/node /usr/local/bin && \
    tar -xzf go.tar.gz -C /usr/local && \
    rm -rf /usr/local/go/test /usr/local/go/doc /usr/local/go/api && \
    tar -xzf openjdk.tar.gz -C /usr/local/java --strip-components=1 && \
    rm -rf /usr/local/java/legal /usr/local/java/man /usr/local/java/demo && \
    tar -xzf maven.tar.gz -C /usr/local/maven --strip-components=1 && \
    tar -xzf uv.tar.gz --strip-components=1 -C /usr/local/bin && \
    tar -xzf node.tar.gz -C /usr/local/node --strip-components=1 && \
    rm -rf /usr/local/node/share/doc /usr/local/node/share/man && \
    ln -sf /usr/local/node/bin/node /usr/local/bin/node && \
    ln -sf /usr/local/node/bin/npm /usr/local/bin/npm && \
    ln -sf /usr/local/node/bin/npx /usr/local/bin/npx && \
    export PATH="/usr/local/node/bin:$PATH" && \
    npm install -g "npm@${NPM_VERSION}" "yarn@${YARN_VERSION}" && \
    npm cache clean --force && \
    ln -sf /usr/local/node/bin/yarn /usr/local/bin/yarn && \
    ln -sf /usr/local/node/bin/yarnpkg /usr/local/bin/yarnpkg && \
    ln -sf /usr/local/node/bin/corepack /usr/local/bin/corepack && \
    tar -xzf betterleaks.tar.gz --exclude=LICENSE --exclude=README.md && \
    mv betterleaks /usr/local/bin/ && \
    tar -xzf helm.tar.gz linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    tar -xzf tf-docs.tar.gz terraform-docs && \
    mv terraform-docs /usr/local/bin/ && \
    tar -xzf helm-docs.tar.gz helm-docs && \
    mv helm-docs /usr/local/bin/ && \
    tar -xzf go-containerregistry.tar.gz crane && \
    mv crane /usr/local/bin/ && \
    tar -xzf actionlint.tar.gz actionlint && \
    mv actionlint /usr/local/bin/ && \
    tar -xzf shellcheck.tar.gz --strip-components=1 "shellcheck-v${SHELLCHECK_VERSION}/shellcheck" && \
    mv shellcheck /usr/local/bin/ && \
    tar -xzf gosec.tar.gz gosec && \
    mv gosec /usr/local/bin/ && \
    tar -xzf golangci-lint.tar.gz --strip-components=1 "golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64/golangci-lint" && \
    mv golangci-lint /usr/local/bin/ && \
    tar -xzf swag.tar.gz swag && \
    mv swag /usr/local/bin/ && \
    tar -xzf tofu.tar.gz tofu && \
    mv tofu /usr/local/bin/ && \
    unzip -o tflint.zip tflint -d /usr/local/bin/ && \
    unzip -o terraform.zip terraform -d /usr/local/bin/ && \
    mv kubectl yq hadolint argocd biome /usr/local/bin/ && \
    chmod -R +x /usr/local/bin/* && \
    rm -rf /tmp/*

COPY --from=registry /usr/local/bin/release-cli /usr/local/bin/release-cli

FROM redhat/ubi9-minimal:${BASE_IMAGE_TAG}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TRIVY_VERSION
ARG HELM_UNITTEST_VERSION
ARG PYTHON_VERSION

WORKDIR /usr/local/bin/

# hadolint ignore=DL3041
RUN microdnf update -y && microdnf upgrade -y && \
    microdnf --nodocs --setopt install_weak_deps=0 install -y \
        yum-utils zip unzip gzip tar xz make which git wget jq openssl less \
        openssh-clients s-nail findutils sshpass rsync buildah podman "python${PYTHON_VERSION}" diffutils patch && \
    yum-config-manager --add-repo "https://download.docker.com/linux/centos/docker-ce.repo" && \
    microdnf install --nodocs --setopt install_weak_deps=0 -y docker-ce-cli && \
    ln -sf "/usr/bin/python${PYTHON_VERSION}" /usr/local/bin/python && \
    ln -sf "/usr/bin/python${PYTHON_VERSION}" /usr/local/bin/python3 && \
    ln -sf "/usr/bin/python${PYTHON_VERSION}" /usr/bin/python && \
    ln -sf "/usr/bin/python${PYTHON_VERSION}" /usr/bin/python3 && \
    dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.rpm" && \
    dnf clean all && \
    microdnf clean all && \
    rm -rf /var/cache/yum /var/cache/dnf /var/cache/microdnf /tmp/*

COPY --from=buildx /buildx /usr/libexec/docker/cli-plugins/docker-buildx
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /usr/local/java /usr/local/java
COPY --from=builder /usr/local/maven /usr/local/maven
COPY --from=builder /usr/local/node /usr/local/node

ENV NODE_HOME="/usr/local/node" \
    NODE_PATH="/usr/local/node" \
    JAVA_HOME="/usr/local/java" \
    MAVEN_HOME="/usr/local/maven" \
    GOPATH="/go" \
    HELM_DATA_HOME="/usr/local/share/helm" \
    PATH="/usr/local/node/bin:/usr/local/go/bin:/go/bin:$PATH"

RUN mkdir -p "${GOPATH}/bin" && \
    ln -sf /usr/local/go/bin/go /usr/local/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt && \
    ln -sf /usr/local/java/bin/java /usr/local/bin/java && \
    ln -sf /usr/local/java/bin/javac /usr/local/bin/javac && \
    ln -sf /usr/local/java/bin/jar /usr/local/bin/jar && \
    ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn && \
    ln -sf /usr/local/node/bin/node /usr/local/bin/node && \
    ln -sf /usr/local/node/bin/npm /usr/local/bin/npm && \
    ln -sf /usr/local/node/bin/npx /usr/local/bin/npx && \
    ln -sf /usr/local/node/bin/yarn /usr/local/bin/yarn && \
    ln -sf /usr/local/node/bin/yarnpkg /usr/local/bin/yarnpkg && \
    ln -sf /usr/local/node/bin/corepack /usr/local/bin/corepack && \
    ln -sf /usr/local/node/bin/node /usr/bin/node && \
    ln -sf /usr/local/node/bin/npm /usr/bin/npm && \
    ln -sf /usr/local/node/bin/npx /usr/bin/npx && \
    ln -sf /usr/local/node/bin/yarn /usr/bin/yarn && \
    ln -sf /usr/local/node/bin/yarnpkg /usr/bin/yarnpkg && \
    ln -sf /usr/local/node/bin/corepack /usr/bin/corepack && \
    mkdir -p /.npm /.config /.npm-global /.npmrc /.yarn && \
    chgrp -R 0 /.npm /.config /.npm-global /.npmrc /.yarn && \
    chmod -R g=u /.npm /.config /.npm-global /.npmrc /.yarn && \
    uv pip install --no-cache --system requests Jinja2 ansible ansible-lint jmespath semantic-version botocore boto3 yamllint pycodestyle isort mypy ruff --python "/usr/bin/python${PYTHON_VERSION}" && \
    helm plugin install https://github.com/helm-unittest/helm-unittest.git --version "v${HELM_UNITTEST_VERSION}" --verify=false && \
    chmod -R a+rx "${HELM_DATA_HOME}" && \
    rm -rf /root/.cache /tmp/*
