#!/bin/bash

# Story 31: Edit Public Access Settings

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Edit Public Access Settings${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

edit_public_access() {
    echo -e "${YELLOW}Select public access configuration:${NC}"
    echo "1. Block all public access (recommended)"
    echo "2. Allow public ACLs only"
    echo "3. Allow public policies only"
    echo "4. Allow all public access (NOT recommended)"
    echo ""
    read -p "Enter choice (1-4): " CHOICE
    
    case $CHOICE in
        1)
            BLOCK_ACLS="true"
            IGNORE_ACLS="true"
            BLOCK_POLICY="true"
            RESTRICT="true"
            ;;
        2)
            BLOCK_ACLS="false"
            IGNORE_ACLS="false"
            BLOCK_POLICY="true"
            RESTRICT="true"
            ;;
        3)
            BLOCK_ACLS="true"
            IGNORE_ACLS="true"
            BLOCK_POLICY="false"
            RESTRICT="false"
            ;;
        4)
            BLOCK_ACLS="false"
            IGNORE_ACLS="false"
            BLOCK_POLICY="false"
            RESTRICT="false"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
            "BlockPublicAcls=$BLOCK_ACLS,IgnorePublicAcls=$IGNORE_ACLS,BlockPublicPolicy=$BLOCK_POLICY,RestrictPublicBuckets=$RESTRICT" \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Public access settings updated${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to update settings${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    edit_public_access
}

main "$@"
