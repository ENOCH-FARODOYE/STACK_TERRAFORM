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
    echo -e "${BLUE}  S3 Object Recovery (Undelete)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_versioning() {
    echo -e "${YELLOW}Checking if versioning is enabled...${NC}"
    VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --region "$AWS_REGION" --query 'Status' --output text 2>&1)
    if [ "$VERSIONING" == "Enabled" ]; then
        echo -e "${GREEN}✓ Versioning is enabled${NC}"
        return 0
    else
        echo -e "${RED}✗ Versioning is NOT enabled. Cannot undelete.${NC}"
        return 1
    fi
}

find_delete_marker() {
    echo -e "${YELLOW}Looking for delete marker...${NC}"
    DELETE_MARKER=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --prefix "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --output text \
        --query 'DeleteMarkers[?IsLatest==`true`].[VersionId]' 2>&1 | head -1)

    if [ -n "$DELETE_MARKER" ] && [ "$DELETE_MARKER" != "None" ]; then
        echo -e "${GREEN}✓ Found delete marker: $DELETE_MARKER${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ No delete marker found. Object may not be deleted.${NC}"
        return 1
    fi
}

remove_delete_marker() {
    echo -e "${YELLOW}Removing delete marker to restore object...${NC}"
    aws s3api delete-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --version-id "$DELETE_MARKER" \
        --region "$AWS_REGION" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Delete marker removed${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to remove delete marker${NC}"
        return 1
    fi
}

verify_restoration() {
    echo -e "${YELLOW}Verifying object restoration...${NC}"
    OBJECT_INFO=$(aws s3api head-object --bucket "$BUCKET_NAME" --key "$OBJECT_KEY" --region "$AWS_REGION" 2>&1)
    if [ $? -eq 0 ]; then
        SIZE=$(echo "$OBJECT_INFO" | grep -o '"ContentLength": [0-9]*' | grep -o '[0-9]*')
        MODIFIED=$(echo "$OBJECT_INFO" | grep -o '"LastModified": "[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}✓ Object successfully restored!${NC}"
        echo -e "${GREEN}  Size: $SIZE bytes${NC}"
        echo -e "${GREEN}  Last Modified: $MODIFIED${NC}"
        return 0
    else
        echo -e "${RED}✗ Object not found after restoration${NC}"
        return 1
    fi
}

main() {
    print_header
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key>${NC}"
        echo -e "${YELLOW}Example: $0 undelete-storage-enoch-v114 test/myfile.txt${NC}"
        exit 1
    fi
    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    check_versioning || exit 1
    echo ""
    find_delete_marker || exit 1
    echo ""
    remove_delete_marker || exit 1
    echo ""
    verify_restoration || exit 1
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Object recovery completed!${NC}"
    echo -e "${GREEN}  $OBJECT_KEY is now accessible${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
