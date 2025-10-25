#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
OBJECT_KEY=""
RETENTION_MODE="GOVERNANCE"
RETENTION_DAYS=30
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Set Object Retention${NC}"
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

get_current_retention() {
    echo -e "${YELLOW}Checking current retention...${NC}"

    RETENTION=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'ObjectLockRetainUntilDate' \
        --output text 2>&1)

    if [ "$RETENTION" != "None" ] && [ ! -z "$RETENTION" ]; then
        echo -e "${YELLOW}⚠ Current retention: $RETENTION${NC}"
        return 0
    else
        echo -e "${GREEN}✓ No current retention set${NC}"
        return 1
    fi
}

set_object_retention() {
    echo -e "${YELLOW}Setting retention on object...${NC}"

    # Calculate retention until date
    if [[ "$OSTYPE" == "darwin"* ]]; then
        RETAIN_UNTIL=$(date -u -v+${RETENTION_DAYS}d +"%Y-%m-%dT%H:%M:%SZ")
    else
        RETAIN_UNTIL=$(date -u -d "+${RETENTION_DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")
    fi

    echo -e "${YELLOW}  Mode: $RETENTION_MODE${NC}"
    echo -e "${YELLOW}  Retain Until: $RETAIN_UNTIL${NC}"
    echo ""

    aws s3api put-object-retention \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --retention "Mode=$RETENTION_MODE,RetainUntilDate=$RETAIN_UNTIL" \
        --region "$AWS_REGION" 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Retention set successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to set retention${NC}"
        return 1
    fi
}

verify_retention() {
    echo -e "${YELLOW}Verifying retention...${NC}"

    VERIFICATION=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query '{Mode: ObjectLockMode, RetainUntil: ObjectLockRetainUntilDate}' \
        --output json 2>&1)

    echo -e "${GREEN}Retention Details:${NC}"
    echo "$VERIFICATION" | jq .
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key> [mode] [days]${NC}"
        echo -e "${YELLOW}Example: $0 object-lock-bucket-enoch-v116 documents/file.txt GOVERNANCE 30${NC}"
        echo ""
        echo -e "${YELLOW}Retention Modes:${NC}"
        echo -e "  GOVERNANCE  - Can be overridden with special permission"
        echo -e "  COMPLIANCE  - Cannot be overridden by anyone"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    RETENTION_MODE="${3:-GOVERNANCE}"
    RETENTION_DAYS="${4:-30}"

    check_object_exists || exit 1
    echo ""
    get_current_retention
    echo ""
    set_object_retention || exit 1
    echo ""
    verify_retention

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Retention set successfully${NC}"
    echo -e "${GREEN}  Protected for $RETENTION_DAYS days${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
