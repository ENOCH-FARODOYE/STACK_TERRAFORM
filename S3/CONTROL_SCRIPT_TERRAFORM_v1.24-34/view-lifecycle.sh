#!/bin/bash

# Story 26: View Lifecycle Policy

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  View Lifecycle Policy${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

view_lifecycle() {
    echo -e "${YELLOW}Retrieving lifecycle configuration...${NC}"
    echo ""
    
    LIFECYCLE=$(aws s3api get-bucket-lifecycle-configuration \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Lifecycle Configuration:${NC}"
        echo "$LIFECYCLE" | jq .
        return 0
    else
        if echo "$LIFECYCLE" | grep -q "NoSuchLifecycleConfiguration"; then
            echo -e "${YELLOW}⚠ No lifecycle configuration found${NC}"
        else
            echo -e "${RED}✗ Error retrieving lifecycle configuration${NC}"
        fi
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
    view_lifecycle
}

main "$@"
