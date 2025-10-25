#!/bin/bash

# Story 28: List CRR Rules

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  List CRR Rules${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

list_rules() {
    echo -e "${YELLOW}Listing replication rules...${NC}"
    echo ""
    
    RULES=$(aws s3api get-bucket-replication \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Replication Rules:${NC}"
        echo "$RULES" | jq .
        return 0
    else
        echo -e "${YELLOW}⚠ No replication rules configured${NC}"
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
    list_rules
}

main "$@"
