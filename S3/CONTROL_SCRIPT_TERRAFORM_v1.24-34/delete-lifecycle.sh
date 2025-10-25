#!/bin/bash

# Story 26: Delete Lifecycle Policy

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Delete Lifecycle Policy${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

delete_lifecycle() {
    echo -e "${YELLOW}Deleting lifecycle configuration...${NC}"
    
    aws s3api delete-bucket-lifecycle \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Lifecycle policy deleted${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to delete lifecycle policy${NC}"
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
    
    read -p "Are you sure you want to delete lifecycle policy? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        delete_lifecycle
    else
        echo -e "${YELLOW}Deletion cancelled${NC}"
    fi
}

main "$@"
