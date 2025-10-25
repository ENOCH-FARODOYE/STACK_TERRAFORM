#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
PREFIX=""
ENCRYPTION_TYPE="AES256"
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Bulk Object Encryption${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

count_objects() {
    TOTAL=$(aws s3 ls "s3://$BUCKET_NAME/$PREFIX" --recursive --region "$AWS_REGION" | wc -l)
    echo -e "${BLUE}Found $TOTAL objects to encrypt${NC}"
    return $TOTAL
}

bulk_encrypt() {
    echo -e "${YELLOW}Starting bulk encryption...${NC}"
    echo ""

    COUNTER=0
    SUCCESS=0
    FAILED=0

    aws s3 ls "s3://$BUCKET_NAME/$PREFIX" --recursive --region "$AWS_REGION" | awk '{print $4}' | while read -r OBJECT_KEY; do
        COUNTER=$((COUNTER + 1))
        echo -e "${YELLOW}[$COUNTER] Encrypting: $OBJECT_KEY${NC}"

        aws s3api copy-object \
            --bucket "$BUCKET_NAME" \
            --key "$OBJECT_KEY" \
            --copy-source "$BUCKET_NAME/$OBJECT_KEY" \
            --server-side-encryption "$ENCRYPTION_TYPE" \
            --metadata-directive COPY \
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
    echo -e "${GREEN}Encryption Summary:${NC}"
    echo -e "${GREEN}  Total: $COUNTER${NC}"
    echo -e "${GREEN}  Success: $SUCCESS${NC}"
    echo -e "${RED}  Failed: $FAILED${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main() {
    print_header

    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> [prefix] [encryption-type]${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket documents/ AES256${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    PREFIX="${2:-}"
    ENCRYPTION_TYPE="${3:-AES256}"

    count_objects
    echo ""

    read -p "Continue with bulk encryption? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        bulk_encrypt
    else
        echo -e "${YELLOW}Bulk encryption cancelled${NC}"
    fi
}

main "$@"
