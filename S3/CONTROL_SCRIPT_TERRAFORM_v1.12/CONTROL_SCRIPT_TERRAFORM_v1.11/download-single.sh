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
    echo -e "${BLUE}  S3 Single File Download${NC}"
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

validate_object_exists() {
    echo -e "${YELLOW}Validating S3 object...${NC}"
    OBJECT_INFO=$(aws s3api head-object --bucket "$BUCKET_NAME" --key "$S3_KEY" --region "$AWS_REGION" 2>&1)
    if [ $? -eq 0 ]; then
        OBJECT_SIZE=$(echo "$OBJECT_INFO" | jq -r '.ContentLength' 2>/dev/null)
        echo -e "${GREEN}✓ Object exists: s3://$BUCKET_NAME/$S3_KEY${NC}"
        echo -e "${GREEN}  Size: $OBJECT_SIZE bytes${NC}"
        return 0
    else
        echo -e "${RED}✗ Object not found: s3://$BUCKET_NAME/$S3_KEY${NC}"
        return 1
    fi
}

validate_local_path() {
    echo -e "${YELLOW}Validating local path...${NC}"
    LOCAL_DIR=$(dirname "$LOCAL_PATH")
    if [ ! -d "$LOCAL_DIR" ]; then
        mkdir -p "$LOCAL_DIR"
        echo -e "${GREEN}✓ Created directory: $LOCAL_DIR${NC}"
    else
        echo -e "${GREEN}✓ Directory exists: $LOCAL_DIR${NC}"
    fi
    return 0
}

download_file() {
    echo -e "${YELLOW}Downloading file from S3...${NC}"
    START_TIME=$(date +%s)
    aws s3 cp "s3://$BUCKET_NAME/$S3_KEY" "$LOCAL_PATH" --region "$AWS_REGION"
    if [ $? -eq 0 ]; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo -e "${GREEN}✓ Download completed in ${DURATION}s${NC}"
        return 0
    else
        echo -e "${RED}✗ Download failed${NC}"
        return 1
    fi
}

verify_download() {
    echo -e "${YELLOW}Verifying download...${NC}"
    if [ -f "$LOCAL_PATH" ]; then
        LOCAL_SIZE=$(stat -c%s "$LOCAL_PATH" 2>/dev/null || stat -f%z "$LOCAL_PATH" 2>/dev/null)
        echo -e "${GREEN}✓ File downloaded successfully${NC}"
        echo -e "${GREEN}  Local path: $LOCAL_PATH${NC}"
        echo -e "${GREEN}  Size: $LOCAL_SIZE bytes${NC}"
        return 0
    else
        echo -e "${RED}✗ File not found locally${NC}"
        return 1
    fi
}

main() {
    print_header
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <s3-key> <local-path>${NC}"
        echo -e "${YELLOW}Example: $0 download-storage-enoch-v111 test/file.txt downloads/file.txt${NC}"
        exit 1
    fi
    BUCKET_NAME="$1"
    S3_KEY="$2"
    LOCAL_PATH="$3"
    validate_bucket_exists || exit 1
    echo ""
    validate_object_exists || exit 1
    echo ""
    validate_local_path || exit 1
    echo ""
    download_file || exit 1
    echo ""
    verify_download || exit 1
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Download completed successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
