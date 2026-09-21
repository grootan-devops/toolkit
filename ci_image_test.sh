#!/usr/bin/env bash
# Smoke test for the CI toolkit image, run inside the built image by docker.yml
# (test: true). The repository root is mounted read-only at the working
# directory, so the Dockerfile itself is the source of truth for every pinned
# version asserted below.
set -uo pipefail

DOCKERFILE="${DOCKERFILE:-Dockerfile}"
FAILURES=0
CHECKS=0

fail() {
    printf '  FAIL  %s\n' "$*" >&2
    FAILURES=$((FAILURES + 1))
}

pass() {
    printf '  ok    %s\n' "$*"
}

section() {
    printf '\n== %s ==\n' "$*"
}

# Value of an `ARG NAME=value` line in the Dockerfile.
arg_value() {
    sed -n "s/^ARG ${1}=\(.*\)$/\1/p" "${DOCKERFILE}" | head -n1
}

# A binary must resolve on PATH and answer a version probe without erroring.
have() {
    local bin="$1"
    shift
    CHECKS=$((CHECKS + 1))

    if ! command -v "${bin}" >/dev/null 2>&1; then
        fail "${bin}: not on PATH"
        return 1
    fi

    if [ "$#" -gt 0 ]; then
        if ! "${bin}" "$@" >/dev/null 2>&1; then
            fail "${bin}: $(command -v "${bin}") exists but '${bin} $*' failed"
            return 1
        fi
    fi

    pass "${bin} -> $(command -v "${bin}")"
    return 0
}

# The version a binary reports must contain the version the Dockerfile pinned.
pinned() {
    local bin="$1" arg="$2"
    shift 2
    CHECKS=$((CHECKS + 1))

    local want
    want="$(arg_value "${arg}")"
    if [ -z "${want}" ]; then
        fail "${bin}: no 'ARG ${arg}=' found in ${DOCKERFILE}"
        return 1
    fi

    local got
    if ! got="$("$@" 2>&1)"; then
        fail "${bin}: version probe '$*' failed"
        return 1
    fi

    case "${got}" in
        *"${want}"*)
            pass "${bin} pinned at ${want}"
            ;;
        *)
            fail "${bin}: expected ${want} (ARG ${arg}), got: $(printf '%s' "${got}" | head -n1)"
            ;;
    esac
}

# A directory named by an environment variable must exist.
env_dir() {
    local name="$1"
    CHECKS=$((CHECKS + 1))

    local value="${!name-}"
    if [ -z "${value}" ]; then
        fail "\$${name} is unset"
    elif [ ! -d "${value}" ]; then
        fail "\$${name}=${value} is not a directory"
    else
        pass "\$${name}=${value}"
    fi
}

if [ ! -f "${DOCKERFILE}" ]; then
    printf 'FATAL: %s not found in %s -- the repository root is not mounted.\n' \
        "${DOCKERFILE}" "$(pwd)" >&2
    exit 1
fi

# Competing PR marker — this build must NOT be the one promoted.
section "Base utilities"
for bin in git jq curl wget tar gzip zip make which openssl less rsync patch diff; do
    have "${bin}" --version
done
have ssh
have sshpass
have find -version
# Info-ZIP unzip predates long options; -v is its version probe.
have unzip -v

section "Python runtime"
have python --version
have python3 --version
pinned python "PYTHON_VERSION" python3 --version

section "Container tooling"
have docker --version
have buildah --version
have podman --version
have crane
have release-cli
CHECKS=$((CHECKS + 1))
if docker buildx version >/dev/null 2>&1; then
    pass "docker buildx CLI plugin installed"
else
    fail "docker buildx: CLI plugin missing or not executable"
fi

section "Go toolchain"
have go version
have gofmt
have golangci-lint --version
have gosec
have swag
pinned go "GO_VERSION" go version
pinned golangci-lint "GOLANGCI_LINT_VERSION" golangci-lint --version

section "Java toolchain"
have java -version
have javac -version
have jar
have mvn -v
pinned mvn "MAVEN_VERSION" mvn -v
CHECKS=$((CHECKS + 1))
JAVA_MAJOR="$(arg_value JAVA_VERSION | cut -d. -f1)"
if java -version 2>&1 | grep -qE "version \"?${JAVA_MAJOR}[.\"]"; then
    pass "java pinned at major ${JAVA_MAJOR}"
else
    fail "java: expected major ${JAVA_MAJOR}, got: $(java -version 2>&1 | head -n1)"
fi

section "Node toolchain"
have node --version
have npm --version
have npx --version
have yarn --version
have yarnpkg --version
have corepack --version
pinned node "NODE_VERSION" node --version
pinned npm "NPM_VERSION" npm --version
pinned yarn "YARN_VERSION" yarn --version

section "Kubernetes & Helm"
have helm version
have kubectl version --client
have helm-docs --version
have argocd
pinned helm "HELM_VERSION" helm version --short
pinned helm-docs "HELM_DOCS_VERSION" helm-docs --version
CHECKS=$((CHECKS + 1))
if helm plugin list 2>/dev/null | grep -q unittest; then
    pass "helm unittest plugin installed"
else
    fail "helm unittest plugin missing"
fi

section "Terraform & OpenTofu"
have terraform version
have tofu version
have tflint --version
have terraform-docs --version
pinned terraform "TERRAFORM_VERSION" terraform version
pinned tofu "TOFU_VERSION" tofu version
pinned tflint "TFLINT_VERSION" tflint --version
pinned terraform-docs "TF_DOCS_VERSION" terraform-docs --version

section "Linters & scanners"
have trivy --version
have hadolint --version
have actionlint -version
have shellcheck --version
have betterleaks
have biome
have yq --version
pinned trivy "TRIVY_VERSION" trivy --version
pinned hadolint "HADOLINT_VERSION" hadolint --version
pinned actionlint "ACTIONLINT_VERSION" actionlint -version
pinned shellcheck "SHELLCHECK_VERSION" shellcheck --version
pinned yq "YQ_VERSION" yq --version

section "Python linting stack"
have uv --version
pinned uv "UV_VERSION" uv --version
for bin in yamllint ruff mypy isort pycodestyle ansible ansible-lint; do
    have "${bin}" --version
done

# Kubernetes tooling reads HOME for its config; a container with none breaks helm.
section "Environment wiring"
env_dir JAVA_HOME
env_dir MAVEN_HOME
env_dir NODE_HOME
env_dir NODE_PATH
env_dir HELM_DATA_HOME
env_dir GOPATH
CHECKS=$((CHECKS + 1))
if [ -n "${GOPATH-}" ]; then
    pass "\$GOPATH=${GOPATH}"
else
    fail "\$GOPATH is unset"
fi

printf '\n== Summary ==\n'
printf '  %d checks, %d failures\n' "${CHECKS}" "${FAILURES}"

if [ "${FAILURES}" -gt 0 ]; then
    printf '\nImage smoke test FAILED.\n' >&2
    exit 1
fi

printf '\nImage smoke test passed.\n'

