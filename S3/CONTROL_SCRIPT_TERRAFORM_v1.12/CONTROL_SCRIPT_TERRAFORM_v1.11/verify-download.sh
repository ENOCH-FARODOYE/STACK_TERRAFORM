#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
S3_KEY=""
LOCAL_PATH=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Download Verification (File Size)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

get_s3_size() {
    echo -e "${YELLOW}Getting S3 file size...${NC}"
    S3_SIZE=$(aws s3api head-object --bucket "$BUCKET_NAME" --key "$S3_KEY" --region "$AWS_REGION" --query 'ContentLength' --output text 2>/dev/null)
    if [ -n "$S3_SIZE" ]; then
        echo -e "${GREEN}✓ S3 file size: $S3_SIZE bytes${NC}"
        return 0
    else
        echo -e "${RED}✗ Could not get S3 file size${NC}"
        return 1
    fi
}

get_local_size() {
    echo -e "${YELLOW}Getting local file size...${NC}"
    if [ -f "$LOCAL_PATH" ]; then
        LOCAL_SIZE=$(stat -c%s "$LOCAL_PATH" 2>/dev/null || stat -f%z "$LOCAL_PATH" 2>/dev/null)
        echo -e "${GREEN}✓ Local file size: $LOCAL_SIZE bytes${NC}"
        return 0
    else
        echo -e "${RED}✗ Local file not found${NC}"
        return 1
    fi
}

compare_sizes() {
    echo -e "${YELLOW}Comparing file sizes...${NC}"
    if [ "$S3_SIZE" == "$LOCAL_SIZE" ]; then
        echo -e "${GREEN}✓ File sizes match! Download verified${NC}"
        echo -e "${GREEN}  Both files are $S3_SIZE bytes${NC}"
        return 0
    else
        echo -e "${RED}✗ File sizes differ!${NC}"
        echo -e "${RED}  S3: $S3_SIZE bytes${NC}"
        echo -e "${RED}  Local: $LOCAL_SIZE bytes${NC}"
        return 1
    fi
}

main() {
    print_header
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <s3-key> <local-path>${NC}"
        exit 1
    fi
    BUCKET_NAME="$1"
    S3_KEY="$2"
    LOCAL_PATH="$3"
    get_s3_size || exit 1
    echo ""
    get_local_size || exit 1
    echo ""
    compare_sizes || exit 1
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Verification completed successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
