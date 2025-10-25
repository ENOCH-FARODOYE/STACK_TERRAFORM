#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Event Notifications Testing${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

validate_bucket_exists() {
    echo -e "${YELLOW}Validating bucket...${NC}"
    if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
        echo -e "${GREEN}✓ Bucket exists: $BUCKET_NAME${NC}"
        return 0
    else
        echo -e "${RED}✗ Bucket not found: $BUCKET_NAME${NC}"
        return 1
    fi
}

get_notification_configuration() {
    echo -e "${YELLOW}Retrieving notification configuration...${NC}"
    NOTIFICATION_CONFIG=$(aws s3api get-bucket-notification-configuration --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Notification configuration found${NC}"
        echo "$NOTIFICATION_CONFIG"
        return 0
    else
        echo -e "${RED}✗ No notification configuration found${NC}"
        return 1
    fi
}

display_notification_details() {
    local config="$1"
    echo ""
    echo -e "${BLUE}Notification Configuration:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    QUEUE_ARN=$(echo "$config" | grep -o '"QueueArn"[^,]*' | cut -d'"' -f4)
    if [ -n "$QUEUE_ARN" ]; then
        echo -e "${GREEN}  Destination Type: SQS Queue${NC}"
        echo -e "${GREEN}  Queue ARN: $QUEUE_ARN${NC}"
        EVENTS=$(echo "$config" | grep -o '"Events":\[[^]]*\]')
        echo -e "${GREEN}  Monitored Events:${NC}"
        echo "$config" | grep -o '"s3:[^"]*"' | sed 's/"//g' | while read event; do
            echo -e "${GREEN}    - $event${NC}"
        done
    else
        echo -e "${YELLOW}  No SQS queue configured${NC}"
    fi
    echo -e "${BLUE}----------------------------------------${NC}"
}

generate_test_events() {
    echo ""
    echo -e "${YELLOW}Generating test events...${NC}"
    echo ""
    echo -e "${BLUE}Test 1: ObjectCreated (PutObject)${NC}"
    echo "Test file for notifications - $(date)" > test-notification-file.txt
    aws s3 cp test-notification-file.txt "s3://$BUCKET_NAME/test-notification-file.txt" --region "$AWS_REGION"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Uploaded test file${NC}"
    fi
    echo ""
    echo -e "${BLUE}Test 2: ObjectRemoved (DeleteObject)${NC}"
    aws s3 rm "s3://$BUCKET_NAME/test-notification-file.txt" --region "$AWS_REGION"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Deleted test file${NC}"
    fi
    rm -f test-notification-file.txt
    echo ""
    echo -e "${YELLOW}⏳ Waiting 5 seconds for events to be processed...${NC}"
    sleep 5
}

main() {
    print_header
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 notifications-bucket-enoch-v110${NC}"
        exit 1
    fi
    BUCKET_NAME="$1"
    validate_bucket_exists || exit 1
    echo ""
    NOTIFICATION_CONFIG=$(get_notification_configuration)
    if [ $? -eq 0 ]; then
        display_notification_details "$NOTIFICATION_CONFIG"
        generate_test_events
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Test events generated${NC}"
        echo -e "${GREEN}  Use receive-messages.sh to see events${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo ""
        echo -e "${RED}Notification testing failed${NC}"
        exit 1
    fi
}

main "$@"
