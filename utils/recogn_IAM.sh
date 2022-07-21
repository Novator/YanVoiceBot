#!/bin/sh

export FOLDER_ID="b1g111111111l8j"
export IAM_TOKEN="t1.9eu111111111111111111111111111111111111111111111111wyBg"

curl -X POST \
     -H "Authorization: Bearer ${IAM_TOKEN}" \
     -H "Transfer-Encoding: chunked" \
     --data-binary "@voice.oga" \
     "https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?topic=general&folderId=${FOLDER_ID}"

