#!/bin/bash

# Story 27: Verify Cross-Region Replication

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE_BUCKET=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Verify CRR Configuration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

verify_replication() {
    echo -e "${YELLOW}Checking replication configuration...${NC}"
    
    REPLICATION=$(aws s3api get-bucket-replication \
        --bucket "$SOURCE_BUCKET" \
        --region "$AWS_REGION" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Replication is configured${NC}"
        echo ""
        echo "$REPLICATION" | jq .
        return 0
    else
        echo -e "${RED}✗ No replication configuration found${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Source bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <source-bucket>${NC}"
        exit 1
    fi
    
    SOURCE_BUCKET="$1"
    verify_replication
}

main "$@"
