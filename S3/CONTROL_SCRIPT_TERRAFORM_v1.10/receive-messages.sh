

#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

QUEUE_URL=""
AWS_REGION="us-east-1"
MAX_MESSAGES=10

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  SQS Messages (S3 Event Notifications)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

receive_messages() {
    echo -e "${YELLOW}Receiving messages from SQS queue...${NC}"
    echo ""
    MESSAGES=$(aws sqs receive-message \
        --queue-url "$QUEUE_URL" \
        --max-number-of-messages "$MAX_MESSAGES" \
        --region "$AWS_REGION" \
        --output text \
        --query 'Messages[*].[Body,ReceiptHandle]' 2>&1)
    if [ $? -eq 0 ] && [ -n "$MESSAGES" ]; then
        echo -e "${GREEN}✓ Messages received${NC}"
        echo "$MESSAGES"
        return 0
    else
        echo -e "${YELLOW}⚠ No messages in queue${NC}"
        return 1
    fi
}

parse_and_display_messages() {
    local messages="$1"
    echo ""
    echo -e "${BLUE}S3 Event Notifications:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    local count=0
    while IFS=$'\t' read -r body receipt; do
        count=$((count + 1))
        echo -e "${GREEN}Message $count:${NC}"
        EVENT_NAME=$(echo "$body" | grep -o '"eventName":"[^"]*' | cut -d'"' -f4)
        BUCKET=$(echo "$body" | grep -o '"name":"[^"]*' | head -1 | cut -d'"' -f4)
        OBJECT_KEY=$(echo "$body" | grep -o '"key":"[^"]*' | cut -d'"' -f4)
        EVENT_TIME=$(echo "$body" | grep -o '"eventTime":"[^"]*' | cut -d'"' -f4)
        echo -e "  Event: ${YELLOW}$EVENT_NAME${NC}"
        echo -e "  Bucket: $BUCKET"
        echo -e "  Object: $OBJECT_KEY"
        echo -e "  Time: $EVENT_TIME"
        echo ""
    done <<< "$messages"
    echo -e "${BLUE}Total messages: $count${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
}

delete_processed_messages() {
    echo ""
    echo -e "${YELLOW}Do you want to delete the received messages? (y/n)${NC}"
    read -r CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo -e "${YELLOW}Deleting messages...${NC}"
        echo "$MESSAGES" | while IFS=$'\t' read -r body receipt; do
            aws sqs delete-message --queue-url "$QUEUE_URL" --receipt-handle "$receipt" --region "$AWS_REGION" 2>/dev/null
        done
        echo -e "${GREEN}✓ Messages deleted${NC}"
    else
        echo -e "${YELLOW}Messages left in queue${NC}"
    fi
}

main() {
    print_header
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Queue URL is required${NC}"
        echo -e "${YELLOW}Usage: $0 <queue-url>${NC}"
        echo -e "${YELLOW}Example: $0 https://sqs.us-east-1.amazonaws.com/123456789012/s3-notifications-queue-v110${NC}"
        echo ""
        echo -e "${YELLOW}Get queue URL from terraform output:${NC}"
        echo -e "  ${GREEN}terraform output sqs_queue_url${NC}"
        exit 1
    fi
    QUEUE_URL="$1"
    MESSAGES=$(receive_messages)
    if [ $? -eq 0 ]; then
        parse_and_display_messages "$MESSAGES"
        delete_processed_messages
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Message retrieval completed${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}  No messages to display${NC}"
        echo -e "${YELLOW}  Generate events with test-notifications.sh${NC}"
        echo -e "${YELLOW}========================================${NC}"
    fi
}

main "$@"
