#!/bin/bash

# Color codes
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
    echo -e "${BLUE}  Create S3 Folder Structure${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

validate_folder_path() {
    echo -e "${YELLOW}Validating folder path...${NC}"
    
    # Ensure path ends with /
    if [[ ! "$FOLDER_PATH" == */ ]]; then
        FOLDER_PATH="$FOLDER_PATH/"
    fi
    
    # Check for valid characters
    if [[ "$FOLDER_PATH" =~ [^a-zA-Z0-9/._-] ]]; then
        echo -e "${RED}✗ Invalid characters in folder path${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Folder path valid: $FOLDER_PATH${NC}"
    return 0
}

create_folder() {
    echo -e "${YELLOW}Creating folder: $FOLDER_PATH${NC}"
    
    # Create zero-byte object to represent folder
    aws s3api put-object \
        --bucket "$BUCKET_NAME" \
        --key "$FOLDER_PATH" \
        --region "$AWS_REGION" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Folder created successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to create folder${NC}"
        return 1
    fi
}

verify_folder() {
    echo -e "${YELLOW}Verifying folder creation...${NC}"
    
    aws s3 ls "s3://$BUCKET_NAME/$FOLDER_PATH" --region "$AWS_REGION" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Folder is visible in S3${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Folder may not be immediately visible${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <folder-path>${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket documents/reports/2024/${NC}"
        echo -e "${YELLOW}Note: Folder path will automatically end with / if not provided${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    FOLDER_PATH="$2"
    
    validate_folder_path || exit 1
    echo ""
    create_folder || exit 1
    echo ""
    verify_folder
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Folder created: $FOLDER_PATH${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
