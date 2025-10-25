#!/bin/bash

# Story 30: Block Public Access

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Block Public Access${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

block_public_access() {
    echo -e "${YELLOW}Blocking all public access...${NC}"
    
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Public access blocked${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to block public access${NC}"
        return 1
    fi
}

verify_settings() {
    echo -e "${YELLOW}Verifying settings...${NC}"
    
    SETTINGS=$(aws s3api get-public-access-block \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --query 'PublicAccessBlockConfiguration' \
        --output json)
    
    echo -e "${GREEN}Current Settings:${NC}"
    echo "$SETTINGS" | jq .
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    
    block_public_access || exit 1
    echo ""
    verify_settings
}

main "$@"
