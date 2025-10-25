#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
OBJECT_KEY=""
LEGAL_HOLD_STATUS="ON"
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Set Legal Hold on Object${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_object_exists() {
    echo -e "${YELLOW}Checking if object exists...${NC}"

    aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Object exists${NC}"
        return 0
    else
        echo -e "${RED}✗ Object does not exist${NC}"
        return 1
    fi
}

get_current_legal_hold() {
    echo -e "${YELLOW}Checking current legal hold status...${NC}"

    HOLD_STATUS=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'ObjectLockLegalHoldStatus' \
        --output text 2>&1)

    if [ "$HOLD_STATUS" == "ON" ]; then
        echo -e "${YELLOW}⚠ Legal hold is currently ON${NC}"
    elif [ "$HOLD_STATUS" == "OFF" ] || [ "$HOLD_STATUS" == "None" ]; then
        echo -e "${GREEN}✓ Legal hold is currently OFF${NC}"
    else
        echo -e "${YELLOW}⚠ Unable to determine legal hold status${NC}"
    fi
}

set_legal_hold() {
    echo -e "${YELLOW}Setting legal hold status to $LEGAL_HOLD_STATUS...${NC}"

    aws s3api put-object-legal-hold \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --legal-hold "Status=$LEGAL_HOLD_STATUS" \
        --region "$AWS_REGION" 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Legal hold set to $LEGAL_HOLD_STATUS${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to set legal hold${NC}"
        return 1
    fi
}

verify_legal_hold() {
    echo -e "${YELLOW}Verifying legal hold status...${NC}"

    VERIFICATION=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'ObjectLockLegalHoldStatus' \
        --output text 2>&1)

    echo -e "${GREEN}Legal Hold Status: $VERIFICATION${NC}"
}

display_legal_hold_info() {
    echo ""
    echo -e "${BLUE}Legal Hold Information:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${GREEN}What is Legal Hold?${NC}"
    echo -e "  • Prevents object deletion indefinitely"
    echo -e "  • No expiration date"
    echo -e "  • Can be turned ON/OFF by authorized users"
    echo -e "  • Independent of retention period"
    echo -e "  • Used for litigation or investigation"
    echo -e "${BLUE}----------------------------------------${NC}"
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key> [ON|OFF]${NC}"
        echo -e "${YELLOW}Example: $0 object-lock-bucket-enoch-v116 documents/file.txt ON${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    LEGAL_HOLD_STATUS="${3:-ON}"

    # Validate legal hold status
    if [[ "$LEGAL_HOLD_STATUS" != "ON" && "$LEGAL_HOLD_STATUS" != "OFF" ]]; then
        echo -e "${RED}Error: Legal hold status must be ON or OFF${NC}"
        exit 1
    fi

    check_object_exists || exit 1
    echo ""
    get_current_legal_hold
    echo ""
    set_legal_hold || exit 1
    echo ""
    verify_legal_hold
    display_legal_hold_info

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Legal hold set to $LEGAL_HOLD_STATUS${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"

