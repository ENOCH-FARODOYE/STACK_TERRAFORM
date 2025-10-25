#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
OBJECT_KEY=""
RESTORE_DAYS=7
RESTORE_TIER="Standard"
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Glacier Object Restoration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_storage_class() {
    echo -e "${YELLOW}Checking object storage class...${NC}"
    STORAGE_CLASS=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'StorageClass' \
        --output text 2>&1)

    if [ "$STORAGE_CLASS" == "GLACIER" ] || [ "$STORAGE_CLASS" == "DEEP_ARCHIVE" ]; then
        echo -e "${GREEN}✓ Object is in $STORAGE_CLASS storage class${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Object is in $STORAGE_CLASS storage class${NC}"
        echo -e "${YELLOW}  (Not in Glacier - restore may not be needed)${NC}"
        return 1
    fi
}

initiate_restore() {
    echo -e "${YELLOW}Initiating restore request...${NC}"
    echo -e "${YELLOW}  Restore Tier: $RESTORE_TIER${NC}"
    echo -e "${YELLOW}  Retention Days: $RESTORE_DAYS${NC}"
    echo ""

    RESTORE_REQUEST='{"Days":'$RESTORE_DAYS',"GlacierJobParameters":{"Tier":"'$RESTORE_TIER'"}}'

    aws s3api restore-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --restore-request "$RESTORE_REQUEST" \
        --region "$AWS_REGION" 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Restore request submitted successfully${NC}"
        return 0
    else
        ERROR=$(aws s3api restore-object \
            --bucket "$BUCKET_NAME" \
            --key "$OBJECT_KEY" \
            --restore-request "$RESTORE_REQUEST" \
            --region "$AWS_REGION" 2>&1)

        if echo "$ERROR" | grep -q "RestoreAlreadyInProgress"; then
            echo -e "${YELLOW}⚠ Restore is already in progress${NC}"
            return 0
        elif echo "$ERROR" | grep -q "ObjectAlreadyInActiveTierError"; then
            echo -e "${GREEN}✓ Object is already restored${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to initiate restore${NC}"
            return 1
        fi
    fi
}

display_restore_info() {
    echo ""
    echo -e "${BLUE}Restore Information:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    case "$RESTORE_TIER" in
        "Expedited")
            echo -e "${GREEN}  Restore Time: 1-5 minutes${NC}"
            echo -e "${YELLOW}  Cost: Highest${NC}"
            ;;
        "Standard")
            echo -e "${GREEN}  Restore Time: 3-5 hours${NC}"
            echo -e "${YELLOW}  Cost: Medium${NC}"
            ;;
        "Bulk")
            echo -e "${GREEN}  Restore Time: 5-12 hours${NC}"
            echo -e "${YELLOW}  Cost: Lowest${NC}"
            ;;
    esac

    echo -e "${GREEN}  Retention: $RESTORE_DAYS days after restore${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key> [restore-days] [tier]${NC}"
        echo -e "${YELLOW}Example: $0 glacier-storage-enoch-v115 archive/myfile.txt 7 Standard${NC}"
        echo ""
        echo -e "${YELLOW}Restore Tiers:${NC}"
        echo -e "  Expedited - 1-5 minutes (highest cost)"
        echo -e "  Standard  - 3-5 hours (default)"
        echo -e "  Bulk      - 5-12 hours (lowest cost)"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    RESTORE_DAYS="${3:-7}"
    RESTORE_TIER="${4:-Standard}"

    check_storage_class
    echo ""
    initiate_restore || exit 1
    display_restore_info
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Restore initiated successfully${NC}"
    echo -e "${GREEN}  Use check-restore-status.sh to monitor${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
