#!/bin/bash

# Story 32: Block Public Access for All Buckets (Account-level)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

AWS_REGION="us-east-1"
ACCOUNT_ID=""

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Block Public Access (Account-Level)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

get_account_id() {
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    echo -e "${GREEN}AWS Account ID: $ACCOUNT_ID${NC}"
    echo ""
}

block_account_public_access() {
    echo -e "${YELLOW}Blocking public access for ALL buckets in account...${NC}"
    echo -e "${RED}⚠ This affects ALL buckets in the account${NC}"
    echo ""
    
    read -p "Type 'CONFIRM' to proceed: " CONFIRM
    if [[ "$CONFIRM" != "CONFIRM" ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
    
    aws s3control put-public-access-block \
        --account-id "$ACCOUNT_ID" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Account-level public access blocked${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to block account-level public access${NC}"
        return 1
    fi
}

verify_account_settings() {
    echo -e "${YELLOW}Verifying account-level settings...${NC}"
    
    SETTINGS=$(aws s3control get-public-access-block \
        --account-id "$ACCOUNT_ID" \
        --region "$AWS_REGION" \
        --query 'PublicAccessBlockConfiguration' \
        --output json)
    
    echo -e "${GREEN}Account Settings:${NC}"
    echo "$SETTINGS" | jq .
}

main() {
    print_header
    get_account_id
    block_account_public_access || exit 1
    echo ""
    verify_account_settings
}

main "$@"
