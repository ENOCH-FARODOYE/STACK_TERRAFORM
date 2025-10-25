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
    echo -e "${BLUE}  Add Metadata to S3 Object${NC}"
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
        return 0
    else
        echo -e "${RED}✗ Object does not exist${NC}"
        return 1
    fi
}

get_current_metadata() {
    echo -e "${YELLOW}Getting current metadata...${NC}"

    CURRENT_METADATA=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'Metadata' \
        --output json 2>&1)

    if [ "$CURRENT_METADATA" == "{}" ] || [ "$CURRENT_METADATA" == "null" ]; then
        echo -e "${YELLOW}⚠ No existing metadata${NC}"
    else
        echo -e "${GREEN}Current metadata:${NC}"
        echo "$CURRENT_METADATA" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
    fi
    echo ""
}

add_metadata() {
    echo -e "${YELLOW}Adding metadata via copy-object...${NC}"

    # Build metadata parameters
    METADATA_ARGS=""
    for META in "$@"; do
        IFS='=' read -r KEY VALUE <<< "$META"
        if [ ! -z "$KEY" ] && [ ! -z "$VALUE" ]; then
            # Remove x-amz-meta- prefix if provided
            KEY=${KEY#x-amz-meta-}
            METADATA_ARGS+="$KEY=$VALUE,"
        fi
    done

    # Remove trailing comma
    METADATA_ARGS=${METADATA_ARGS%,}

    echo -e "${YELLOW}Metadata: $METADATA_ARGS${NC}"
    echo ""

    aws s3api copy-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --copy-source "$BUCKET_NAME/$OBJECT_KEY" \
        --metadata "$METADATA_ARGS" \
        --metadata-directive REPLACE \
        --region "$AWS_REGION" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Metadata added successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to add metadata${NC}"
        return 1
    fi
}

verify_metadata() {
    echo -e "${YELLOW}Verifying new metadata...${NC}"

    NEW_METADATA=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'Metadata' \
        --output json 2>&1)

    echo -e "${GREEN}New metadata:${NC}"
    echo "$NEW_METADATA" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
}

main() {
    print_header

    if [ $# -lt 3 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key> <key1>=<value1> [key2=value2] ...${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket docs/file.txt author=John department=Engineering${NC}"
        echo -e "${YELLOW}Note: Metadata keys will automatically get 'x-amz-meta-' prefix${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    shift 2

    check_object_exists || exit 1
    echo ""
    get_current_metadata
    add_metadata "$@" || exit 1
    echo ""
    verify_metadata

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Metadata applied successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
