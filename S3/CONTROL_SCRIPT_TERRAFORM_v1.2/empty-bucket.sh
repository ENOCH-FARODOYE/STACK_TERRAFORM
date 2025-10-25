#!/bin/bash

# Usage: ./empty-bucket.sh <bucket-name> [--dry-run]
# Example: AWS_PROFILE=stack_admin_enoch ./empty-bucket.sh stack-bulk1-enoch --dry-run

set -e

BUCKET="$1"
DRY_RUN=false

if [[ -z "$BUCKET" ]]; then
    echo "Usage: $0 <bucket-name> [--dry-run]"
    exit 1
fi

# Check for dry-run flag
if [[ "$2" == "--dry-run" ]]; then
    DRY_RUN=true
fi

echo "Bucket: $BUCKET"
echo "Dry run: $DRY_RUN"

# Function to run AWS CLI with optional dry-run
aws_cmd() {
    if $DRY_RUN; then
        echo "Dry run: would execute -> aws $*"
    else
        aws "$@"
    fi
}

# Check if bucket exists and is accessible
if ! aws_cmd s3 ls "s3://$BUCKET" > /dev/null 2>&1; then
    echo "Bucket does not exist or not accessible"
    exit 1
fi

echo "Deleting all objects in $BUCKET..."
aws_cmd s3 rm "s3://$BUCKET" --recursive --profile "${AWS_PROFILE:-default}"

echo "Deleting all object versions in $BUCKET..."
VERSIONS_JSON=$(aws_cmd s3api list-object-versions --bucket "$BUCKET" --profile "${AWS_PROFILE:-default}")
if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run: would delete versions:"
    echo "$VERSIONS_JSON"
else
    # Delete all versions
    echo "$VERSIONS_JSON" | jq -r '.Versions[] | [.Key, .VersionId] | @tsv' | while IFS=$'\t' read -r key version; do
        aws_cmd s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$version" --profile "${AWS_PROFILE:-default}"
    done
fi

echo "Aborting incomplete multipart uploads..."
UPLOADS_JSON=$(aws_cmd s3api list-multipart-uploads --bucket "$BUCKET" --profile "${AWS_PROFILE:-default}")
if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run: would abort multipart uploads:"
    echo "$UPLOADS_JSON"
else
    echo "$UPLOADS_JSON" | jq -r '.Uploads[] | .UploadId + " " + .Key' | while read -r upload_id key; do
        aws_cmd s3api abort-multipart-upload --bucket "$BUCKET" --key "$key" --upload-id "$upload_id" --profile "${AWS_PROFILE:-default}"
    done
fi

echo "Bucket emptying process completed."

