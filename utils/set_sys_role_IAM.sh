#!/bin/sh

export FOLDER_ID="b1g111111111l8j"
export IAM_TOKEN="t1.9eu111111111111111111111111111111111111111111111111wyBg"

curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${IAM_TOKEN}" \
  -d '@body2.json' \
  "https://resource-manager.api.cloud.yandex.net/resource-manager/v1/folders/${FOLDER_ID}:updateAccessBindings"

