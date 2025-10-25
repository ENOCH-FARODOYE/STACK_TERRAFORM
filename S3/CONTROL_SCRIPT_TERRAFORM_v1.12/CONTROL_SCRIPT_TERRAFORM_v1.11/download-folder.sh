#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
S3_PREFIX=""
LOCAL_PATH=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Folder Download (Recursive)${NC}"
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

check_objects_exist() {
    echo -e "${YELLOW}Checking for objects in S3...${NC}"
    OBJECT_COUNT=$(aws s3 ls "s3://$BUCKET_NAME/$S3_PREFIX" --recursive --region "$AWS_REGION" 2>/dev/null | wc -l)
    if [ "$OBJECT_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $OBJECT_COUNT object(s) to download${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ No objects found at s3://$BUCKET_NAME/$S3_PREFIX${NC}"
        return 1
    fi
}

validate_local_path() {
    echo -e "${YELLOW}Validating local path...${NC}"
    if [ ! -d "$LOCAL_PATH" ]; then
        mkdir -p "$LOCAL_PATH"
        echo -e "${GREEN}✓ Created directory: $LOCAL_PATH${NC}"
    else
        echo -e "${GREEN}✓ Directory exists: $LOCAL_PATH${NC}"
    fi
    return 0
}

download_folder() {
    echo -e "${YELLOW}Downloading folder from S3...${NC}"
    echo ""
    START_TIME=$(date +%s)
    aws s3 sync "s3://$BUCKET_NAME/$S3_PREFIX" "$LOCAL_PATH" --region "$AWS_REGION"
    if [ $? -eq 0 ]; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo -e "${GREEN}✓ Download completed in ${DURATION}s${NC}"
        return 0
    else
        echo -e "${RED}✗ Download failed${NC}"
        return 1
    fi
}


