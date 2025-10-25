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
    echo -e "${BLUE}  Glacier Restore Status${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_restore_status() {
    echo -e "${YELLOW}Checking restore status...${NC}"

    RESTORE_STATUS=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'Restore' \
        --output text 2>&1)

    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Could not retrieve object information${NC}"
        return 1
    fi

    if echo "$RESTORE_STATUS" | grep -q "ongoing-request"; then
        echo -e "${YELLOW}⏳ Restore is IN PROGRESS${NC}"
        echo -e "${YELLOW}   Please wait and check again later${NC}"
        return 2
    elif echo "$RESTORE_STATUS" | grep -q "ongoing-request.*false"; then
        EXPIRY=$(echo "$RESTORE_STATUS" | grep -o 'expiry-date="[^"]*"' | cut -d'"' -f2)
        echo -e "${GREEN}✓ Object is RESTORED and available${NC}"
        echo -e "${GREEN}  Available until: $EXPIRY${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ No restore in progress${NC}"
        echo -e "${YELLOW}  Object may not be archived or restore not initiated${NC}"
        return 3
    fi
}

display_object_info() {
    echo ""
    echo -e "${BLUE}Object Information:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    OBJ_INFO=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" 2>&1)

    SIZE=$(echo "$OBJ_INFO" | grep -o '"ContentLength": [0-9]*' | grep -o '[0-9]*')
    STORAGE=$(echo "$OBJ_INFO" | grep -o '"StorageClass": "[^"]*"' | cut -d'"' -f4)
    MODIFIED=$(echo "$OBJ_INFO" | grep -o '"LastModified": "[^"]*"' | cut -d'"' -f4)

    echo -e "${GREEN}  Size: $SIZE bytes${NC}"
    echo -e "${GREEN}  Storage Class: $STORAGE${NC}"
    echo -e "${GREEN}  Last Modified: $MODIFIED${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key>${NC}"
        echo -e "${YELLOW}Example: $0 glacier-storage-enoch-v115 archive/myfile.txt${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"

    check_restore_status
    STATUS=$?

    display_object_info

    echo ""
    if [ $STATUS -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Object is ready to download${NC}"
        echo -e "${GREEN}========================================${NC}"
    elif [ $STATUS -eq 2 ]; then
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}  Restore in progress - check back later${NC}"
        echo -e "${YELLOW}========================================${NC}"
    fi
}

main "$@"
