#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
OBJECT_KEY=""
VERSION_ID=""
OUTPUT_FILE=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Download Specific Object Version${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

download_version() {
    echo -e "${YELLOW}Downloading version: $VERSION_ID${NC}"

    if [ -z "$OUTPUT_FILE" ]; then
        OUTPUT_FILE="${OBJECT_KEY##*/}_${VERSION_ID}"
    fi

    aws s3api get-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --version-id "$VERSION_ID" \
        --region "$AWS_REGION" \
        "$OUTPUT_FILE" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Version downloaded successfully${NC}"
        echo -e "${GREEN}  Output file: $OUTPUT_FILE${NC}"

        FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
        echo -e "${GREEN}  File size: $FILE_SIZE${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to download version${NC}"
        return 1
    fi
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key> <version-id> [output-file]${NC}"
        echo -e "${YELLOW}Example: $0 versioned-bucket-enoch-v117 docs/file.txt v123456 file_v1.txt${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    VERSION_ID="$3"
    OUTPUT_FILE="$4"

    download_version || exit 1

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Download complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"

