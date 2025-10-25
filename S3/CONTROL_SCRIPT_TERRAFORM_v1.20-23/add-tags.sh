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
    echo -e "${BLUE}  Add Tags to S3 Object${NC}"
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

get_current_tags() {
    echo -e "${YELLOW}Getting current tags...${NC}"

    CURRENT_TAGS=$(aws s3api get-object-tagging \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'TagSet' \
        --output json 2>&1)

    if [ "$CURRENT_TAGS" == "[]" ]; then
        echo -e "${YELLOW}⚠ No existing tags${NC}"
    else
        echo -e "${GREEN}Current tags:${NC}"
        echo "$CURRENT_TAGS" | jq -r '.[] | "  \(.Key): \(.Value)"'
    fi
    echo ""
}

add_tags() {
    echo -e "${YELLOW}Adding/updating tags...${NC}"

    # Build tag JSON from arguments
    TAG_JSON='{"TagSet":['
    FIRST=true

    for TAG in "$@"; do
        IFS='=' read -r KEY VALUE <<< "$TAG"
        if [ ! -z "$KEY" ] && [ ! -z "$VALUE" ]; then
            if [ "$FIRST" = true ]; then
                FIRST=false
            else
                TAG_JSON+=','
            fi
            TAG_JSON+="{\"Key\":\"$KEY\",\"Value\":\"$VALUE\"}"
        fi
    done

    TAG_JSON+=']}'

    echo -e "${YELLOW}Tag JSON: $TAG_JSON${NC}"
    echo ""

    aws s3api put-object-tagging \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --tagging "$TAG_JSON" \
        --region "$AWS_REGION" 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Tags added successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to add tags${NC}"
        return 1
    fi
}

verify_tags() {
    echo -e "${YELLOW}Verifying new tags...${NC}"

    NEW_TAGS=$(aws s3api get-object-tagging \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'TagSet' \
        --output json 2>&1)

    echo -e "${GREEN}New tags:${NC}"
    echo "$NEW_TAGS" | jq -r '.[] | "  \(.Key): \(.Value)"'
}

main() {
    print_header

    if [ $# -lt 3 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key> <key1>=<value1> [key2=value2] ...${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket docs/file.txt Environment=Production Team=Engineering${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    shift 2

    check_object_exists || exit 1
    echo ""
    get_current_tags
    add_tags "$@" || exit 1
    echo ""
    verify_tags

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Tags applied successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
