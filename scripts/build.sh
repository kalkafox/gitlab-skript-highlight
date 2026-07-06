#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-gitlab}"
GITLAB_IMAGE="${GITLAB_IMAGE:-}"
OUTPUT_IMAGE="${OUTPUT_IMAGE:-gitlab-skript:local}"

if [[ -z "${GITLAB_IMAGE}" ]]; then
  if docker inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    GITLAB_IMAGE="$(docker inspect "${CONTAINER_NAME}" --format '{{.Config.Image}}')"
  else
    echo "Set GITLAB_IMAGE, or set CONTAINER_NAME to an existing GitLab container." >&2
    echo "Example: GITLAB_IMAGE=gitlab/gitlab-ee:18.10.1-ee.0 OUTPUT_IMAGE=gitlab-ee-skript:18.10.1 ./scripts/build.sh" >&2
    exit 1
  fi
fi

echo "Base GitLab image: ${GITLAB_IMAGE}"
echo "Output image:      ${OUTPUT_IMAGE}"

docker build \
  --build-arg "GITLAB_IMAGE=${GITLAB_IMAGE}" \
  -t "${OUTPUT_IMAGE}" \
  .
