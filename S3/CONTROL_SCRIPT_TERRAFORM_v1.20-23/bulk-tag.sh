#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
PREFIX=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Bulk Object Tagging${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

bulk_tag() {
    echo -e "${YELLOW}Starting bulk tagging...${NC}"
    echo ""

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

    echo -e "${BLUE}Tags to apply: $TAG_JSON${NC}"
    echo ""

    COUNTER=0
    SUCCESS=0
    FAILED=0

    aws s3 ls "s3://$BUCKET_NAME/$PREFIX" --recursive --region "$AWS_REGION" | awk '{print $4}' | while read -r OBJECT_KEY; do
        COUNTER=$((COUNTER + 1))
        echo -e "${YELLOW}[$COUNTER] Tagging: $OBJECT_KEY${NC}"

        aws s3api put-object-tagging \
            --bucket "$BUCKET_NAME" \
            --key "$OBJECT_KEY" \
            --tagging "$TAG_JSON" \
            --region "$AWS_REGION" > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Success${NC}"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "${RED}✗ Failed${NC}"
            FAILED=$((FAILED + 1))
        fi
        echo ""
    done

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Tagging Summary:${NC}"
    echo -e "${GREEN}  Total: $COUNTER${NC}"
    echo -e "${GREEN}  Success: $SUCCESS${NC}"
    echo -e "${RED}  Failed: $FAILED${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main() {
    print_header

    if [ $# -lt 3 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <prefix> <key1>=<value1> [key2=value2] ...${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket documents/ Environment=Production Team=Eng${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    PREFIX="$2"
    shift 2

    read -p "Continue with bulk tagging? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        bulk_tag "$@"
    else
        echo -e "${YELLOW}Bulk tagging cancelled${NC}"
    fi
}

main "$@"

