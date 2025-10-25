#!/bin/bash

# Story 25: Delete Folders from S3 Bucket

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
FOLDER_PATH=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Delete S3 Folder${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

count_objects() {
    if [[ ! "$FOLDER_PATH" == */ ]]; then
        FOLDER_PATH="$FOLDER_PATH/"
    fi
    
    OBJECT_COUNT=$(aws s3 ls "s3://$BUCKET_NAME/$FOLDER_PATH" --recursive --region "$AWS_REGION" | wc -l)
    echo -e "${YELLOW}Objects in folder: $OBJECT_COUNT${NC}"
    
    if [ $OBJECT_COUNT -gt 0 ]; then
        echo -e "${RED}⚠ WARNING: This will permanently delete all $OBJECT_COUNT objects!${NC}"
    fi
}

delete_folder() {
    echo ""
    echo -e "${YELLOW}Deleting folder: $FOLDER_PATH${NC}"
    
    aws s3 rm "s3://$BUCKET_NAME/$FOLDER_PATH" --recursive --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Folder deleted successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to delete folder${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <folder-path>${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket documents/old/${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    FOLDER_PATH="$2"
    
    count_objects
    echo ""
    
    read -p "Type 'DELETE' to confirm deletion: " CONFIRM
    if [[ "$CONFIRM" == "DELETE" ]]; then
        delete_folder
    else
        echo -e "${YELLOW}Deletion cancelled${NC}"
    fi
}

main "$@"

