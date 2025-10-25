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
    echo -e "${BLUE}  S3 Object Versions${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

list_versions() {
    echo -e "${YELLOW}Listing all versions of: $OBJECT_KEY${NC}"
    echo ""

    VERSIONS=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --prefix "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --output text \
        --query 'Versions[*].[VersionId,LastModified,Size,IsLatest]' 2>&1)

    if [ $? -eq 0 ] && [ -n "$VERSIONS" ]; then
        echo -e "${BLUE}Object Versions:${NC}"
        echo -e "${BLUE}----------------------------------------${NC}"
        echo "$VERSIONS" | while IFS=$'\t' read -r version_id modified size is_latest; do
            if [ "$is_latest" == "True" ]; then
                echo -e "${GREEN}  Version: $version_id (CURRENT)${NC}"
            else
                echo -e "${YELLOW}  Version: $version_id${NC}"
            fi
            echo -e "    Modified: $modified"
            echo -e "    Size: $size bytes"
            echo ""
        done
        echo -e "${BLUE}----------------------------------------${NC}"
        return 0
    fi

    DELETE_MARKERS=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --prefix "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --output text \
        --query 'DeleteMarkers[*].[VersionId,LastModified,IsLatest]' 2>&1)

    if [ $? -eq 0 ] && [ -n "$DELETE_MARKERS" ]; then
        echo -e "${RED}Object is DELETED (Delete Marker exists)${NC}"
        echo -e "${BLUE}Delete Markers:${NC}"
        echo -e "${BLUE}----------------------------------------${NC}"
        echo "$DELETE_MARKERS" | while IFS=$'\t' read -r version_id modified is_latest; do
            if [ "$is_latest" == "True" ]; then
                echo -e "${RED}  Delete Marker: $version_id (CURRENT)${NC}"
            else
                echo -e "${YELLOW}  Delete Marker: $version_id${NC}"
            fi
            echo -e "    Created: $modified"
            echo ""
        done
        echo -e "${BLUE}----------------------------------------${NC}"
        return 0
    fi

    echo -e "${YELLOW}⚠ No versions found for this object${NC}"
    return 1
}

main() {
    print_header
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key>${NC}"
        echo -e "${YELLOW}Example: $0 undelete-storage-enoch-v114 test/myfile.txt${NC}"
        exit 1
    fi
    BUCKET_NAME="$1"
    OBJECT_KEY="$2"
    list_versions
}

main "$@"
