#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
OBJECT_KEY=""
ENCRYPTION_TYPE="AES256"
KMS_KEY_ID=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Encrypt S3 Object${NC}"
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

check_current_encryption() {
    echo -e "${YELLOW}Checking current encryption status...${NC}"

    CURRENT_ENCRYPTION=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'ServerSideEncryption' \
        --output text 2>&1)

    if [ "$CURRENT_ENCRYPTION" == "None" ] || [ -z "$CURRENT_ENCRYPTION" ]; then
        echo -e "${YELLOW}⚠ Object is not encrypted${NC}"
    else
        echo -e "${GREEN}Current encryption: $CURRENT_ENCRYPTION${NC}"
    fi
}

encrypt_object() {
    echo ""
    echo -e "${YELLOW}Encrypting object with $ENCRYPTION_TYPE...${NC}"

    if [ "$ENCRYPTION_TYPE" == "aws:kms" ] && [ ! -z "$KMS_KEY_ID" ]; then
        aws s3api copy-object \
            --bucket "$BUCKET_NAME" \
            --key "$OBJECT_KEY" \
            --copy-source "$BUCKET_NAME/$OBJECT_KEY" \
            --server-side-encryption "$ENCRYPTION_TYPE" \
            --ssekms-key-id "$KMS_KEY_ID" \
            --metadata-directive COPY \
            --region "$AWS_REGION" > /dev/null 2>&1
    else
        aws s3api copy-object \
            --bucket "$BUCKET_NAME" \
            --key "$OBJECT_KEY" \
            --copy-source "$BUCKET_NAME/$OBJECT_KEY" \
            --server-side-encryption "$ENCRYPTION_TYPE" \
            --metadata-directive COPY \
            --region "$AWS_REGION" > /dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Object encrypted successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to encrypt object${NC}"
        return 1
    fi
}

verify_encryption() {
    echo -e "${YELLOW}Verifying encryption...${NC}"

    NEW_ENCRYPTION=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'ServerSideEncryption' \
        --output text 2>&1)

    echo -e "${GREEN}New encryption: $NEW_ENCRYPTION${NC}"

    if [ "$ENCRYPTION_TYPE" == "aws:kms" ]; then
        KMS_ID=$(aws s3api head-object \
            --bucket "$BUCKET_NAME" \
            --key "$OBJECT_KEY" \
            --region "$AWS_REGION" \
            --query 'SSEKMSKeyId' \
            --output text 2>&1)

        if [ "$KMS_ID" != "None" ]; then
            echo -e "${GREEN}KMS Key ID: $KMS_ID${NC}"
        fi
    fi
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key> [encryption-type] [kms-key-id]${NC}"
        echo -e "${YELLOW}Example (SSE-S3): $0 my-bucket docs/file.txt AES256${NC}"
        echo -e "${YELLOW}Example (SSE-KMS): $0 my-bucket docs/file.txt aws:kms key-id-123${NC}"
        echo ""
        echo -e "${YELLOW}Encryption Types:${NC}"
        echo -e "  AES256   - SSE-S3 (default)"
        echo -e "  aws:kms  - SSE-KMS (requires key ID)"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    ENCRYPTION_TYPE="${3:-AES256}"
    KMS_KEY_ID="$4"

    check_object_exists || exit 1
    echo ""
    check_current_encryption
    encrypt_object || exit 1
    echo ""
    verify_encryption

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Encryption applied successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
