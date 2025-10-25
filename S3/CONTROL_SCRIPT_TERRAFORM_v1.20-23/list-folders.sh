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
    echo -e "${BLUE}  List S3 Folders${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

list_folders() {
    echo -e "${YELLOW}Listing folders in: s3://$BUCKET_NAME/$PREFIX${NC}"
    echo ""
    
    FOLDERS=$(aws s3 ls "s3://$BUCKET_NAME/$PREFIX" --region "$AWS_REGION" | grep "PRE" | awk '{print $2}')
    
    if [ -z "$FOLDERS" ]; then
        echo -e "${YELLOW}⚠ No folders found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Folders:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo "$FOLDERS" | while read -r FOLDER; do
        echo -e "${GREEN}📁 $FOLDER${NC}"
    done
    echo -e "${BLUE}----------------------------------------${NC}"
    
    FOLDER_COUNT=$(echo "$FOLDERS" | wc -l)
    echo -e "${GREEN}Total folders: $FOLDER_COUNT${NC}"
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> [prefix]${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket documents/${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    PREFIX="${2:-}"
    
    list_folders
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Folder listing complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
