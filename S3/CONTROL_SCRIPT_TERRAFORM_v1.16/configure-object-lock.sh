#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
LOCK_MODE="GOVERNANCE"
RETENTION_DAYS=30
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Object Lock Configuration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_object_lock_status() {
    echo -e "${YELLOW}Checking Object Lock status...${NC}"

    LOCK_STATUS=$(aws s3api get-object-lock-configuration \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" 2>&1)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Object Lock is enabled${NC}"
        echo "$LOCK_STATUS"
        return 0
    else
        if echo "$LOCK_STATUS" | grep -q "ObjectLockConfigurationNotFoundError"; then
            echo -e "${RED}✗ Object Lock is not enabled${NC}"
            echo -e "${YELLOW}  Note: Object Lock can only be enabled during bucket creation${NC}"
        else
            echo -e "${RED}✗ Error checking Object Lock status${NC}"
        fi
        return 1
    fi
}

update_object_lock_config() {
    echo -e "${YELLOW}Updating Object Lock configuration...${NC}"
    echo -e "${YELLOW}  Mode: $LOCK_MODE${NC}"
    echo -e "${YELLOW}  Retention: $RETENTION_DAYS days${NC}"
    echo ""

    LOCK_CONFIG=$(cat <<EOF
{
  "ObjectLockEnabled": "Enabled",
  "Rule": {
    "DefaultRetention": {
      "Mode": "$LOCK_MODE",
      "Days": $RETENTION_DAYS
    }
  }
}
EOF
)

    aws s3api put-object-lock-configuration \
        --bucket "$BUCKET_NAME" \
        --object-lock-configuration "$LOCK_CONFIG" \
        --region "$AWS_REGION" 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Object Lock configuration updated successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to update Object Lock configuration${NC}"
        return 1
    fi
}

display_retention_info() {
    echo ""
    echo -e "${BLUE}Object Lock Modes:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    case "$LOCK_MODE" in
        "GOVERNANCE")
            echo -e "${GREEN}Mode: GOVERNANCE${NC}"
            echo -e "  • Users with special permissions can override"
            echo -e "  • Can shorten/extend retention period"
            echo -e "  • Can remove retention altogether"
            echo -e "  • Use for: Testing and flexible protection"
            ;;
        "COMPLIANCE")
            echo -e "${GREEN}Mode: COMPLIANCE${NC}"
            echo -e "  • NO ONE can override (including root)"
            echo -e "  • Cannot shorten retention period"
            echo -e "  • Cannot delete object until retention expires"
            echo -e "  • Use for: Regulatory compliance"
            ;;
    esac

    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${GREEN}Retention Period: $RETENTION_DAYS days${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
}

main() {
    print_header

    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> [mode] [days]${NC}"
        echo -e "${YELLOW}Example: $0 object-lock-bucket-enoch-v116 GOVERNANCE 30${NC}"
        echo ""
        echo -e "${YELLOW}Modes:${NC}"
        echo -e "  GOVERNANCE  - Can be overridden by authorized users"
        echo -e "  COMPLIANCE  - Cannot be overridden by anyone"
        exit 1
    fi

    BUCKET_NAME="$1"
    LOCK_MODE="${2:-GOVERNANCE}"
    RETENTION_DAYS="${3:-30}"

    check_object_lock_status
    echo ""

    read -p "Do you want to update the Object Lock configuration? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        update_object_lock_config || exit 1
        display_retention_info
    else
        echo -e "${YELLOW}Configuration update cancelled${NC}"
    fi

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Object Lock configuration complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
