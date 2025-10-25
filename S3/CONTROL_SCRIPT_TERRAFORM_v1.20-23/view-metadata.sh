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
    echo -e "${BLUE}  View Object Metadata${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

view_metadata() {
    echo -e "${YELLOW}Retrieving metadata...${NC}"
    
    METADATA=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'Metadata' \
        --output json 2>&1)
    
    if [ "$METADATA" == "{}" ] || [ "$METADATA" == "null" ]; then
        echo -e "${YELLOW}⚠ No metadata found${NC}"
    else
        echo -e "${GREEN}Metadata:${NC}"
        echo "$METADATA" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
    fi
}

main() {
    print_header
    
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key>${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket docs/file.txt${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    
    view_metadata
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Metadata retrieved${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
