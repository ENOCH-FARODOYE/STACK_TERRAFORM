

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
    echo -e "${BLUE}  Remove Tags from S3 Object${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

remove_all_tags() {
    echo -e "${YELLOW}Removing all tags...${NC}"

    aws s3api delete-object-tagging \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ All tags removed${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to remove tags${NC}"
        return 1
    fi
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key>${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket docs/file.txt${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"

    remove_all_tags || exit 1

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Tags removed successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
