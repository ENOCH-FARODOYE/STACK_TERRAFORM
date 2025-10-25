#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
OBJECT_KEY=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Object Properties${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_object_exists() {
    echo -e "${YELLOW}Checking if object exists...${NC}"

    aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Object exists${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Object does not exist${NC}"
        return 1
    fi
}

display_basic_properties() {
    echo -e "${BLUE}Basic Properties:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    PROPERTIES=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" 2>&1)

    # Extract properties
    SIZE=$(echo "$PROPERTIES" | jq -r '.ContentLength')
    CONTENT_TYPE=$(echo "$PROPERTIES" | jq -r '.ContentType')
    LAST_MODIFIED=$(echo "$PROPERTIES" | jq -r '.LastModified')
    ETAG=$(echo "$PROPERTIES" | jq -r '.ETag')

    echo -e "${GREEN}Size: $SIZE bytes ($(numfmt --to=iec-i --suffix=B $SIZE 2>/dev/null || echo $SIZE))${NC}"
    echo -e "${GREEN}Content Type: $CONTENT_TYPE${NC}"
    echo -e "${GREEN}Last Modified: $LAST_MODIFIED${NC}"
    echo -e "${GREEN}ETag: $ETAG${NC}"
}

display_storage_class() {
    echo ""
    echo -e "${BLUE}Storage:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    STORAGE_CLASS=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'StorageClass' \
        --output text 2>&1)

    if [ "$STORAGE_CLASS" == "None" ] || [ -z "$STORAGE_CLASS" ]; then
        STORAGE_CLASS="STANDARD"
    fi

    echo -e "${GREEN}Storage Class: $STORAGE_CLASS${NC}"
}

display_encryption() {
    echo ""
    echo -e "${BLUE}Encryption:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    ENCRYPTION=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'ServerSideEncryption' \
        --output text 2>&1)

    if [ "$ENCRYPTION" == "None" ] || [ -z "$ENCRYPTION" ]; then
        echo -e "${YELLOW}Encryption: Not encrypted${NC}"
    else
        echo -e "${GREEN}Encryption: $ENCRYPTION${NC}"

        KMS_KEY=$(aws s3api head-object \
            --bucket "$BUCKET_NAME" \
            --key "$OBJECT_KEY" \
            --region "$AWS_REGION" \
            --query 'SSEKMSKeyId' \
            --output text 2>&1)

        if [ "$KMS_KEY" != "None" ] && [ ! -z "$KMS_KEY" ]; then
            echo -e "${GREEN}KMS Key ID: $KMS_KEY${NC}"
        fi
    fi
}

display_versioning() {
    echo ""
    echo -e "${BLUE}Versioning:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    VERSION_ID=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'VersionId' \
        --output text 2>&1)

    if [ "$VERSION_ID" != "None" ] && [ ! -z "$VERSION_ID" ]; then
        echo -e "${GREEN}Version ID: $VERSION_ID${NC}"
    else
        echo -e "${YELLOW}Versioning: Not enabled or no version ID${NC}"
    fi
}

display_metadata() {
    echo ""
    echo -e "${BLUE}Custom Metadata:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    METADATA=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'Metadata' \
        --output json 2>&1)

    if [ "$METADATA" == "{}" ] || [ "$METADATA" == "null" ]; then
        echo -e "${YELLOW}No custom metadata${NC}"
    else
        echo "$METADATA" | jq -r 'to_entries[] | "\(.key): \(.value)"' | while read -r line; do
            echo -e "${GREEN}$line${NC}"
        done
    fi
}

display_tags() {
    echo ""
    echo -e "${BLUE}Tags:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    TAGS=$(aws s3api get-object-tagging \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'TagSet' \
        --output json 2>&1)

    if [ "$TAGS" == "[]" ] || [ "$TAGS" == "null" ]; then
        echo -e "${YELLOW}No tags${NC}"
    else
        echo "$TAGS" | jq -r '.[] | "\(.Key): \(.Value)"' | while read -r line; do
            echo -e "${GREEN}$line${NC}"
        done
    fi
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key>${NC}"
        echo -e "${YELLOW}Example: $0 versioned-bucket-enoch-v118 documents/file.txt${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"

    check_object_exists || exit 1
    display_basic_properties
    display_storage_class
    display_encryption
    display_versioning
    display_metadata
    display_tags

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Properties retrieved successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
