

#!/bin/bash

#######################################
# Script: verify-tags.sh
# Purpose: List and verify S3 bucket tags
# Story: CONTROL_SCRIPT_TERRAFORM_v1.3
#######################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUCKET_NAME=""
AWS_REGION="us-east-1"
AWS_ACCESS_KEY=""
AWS_SECRET_KEY=""

#######################################
# Function: print_header
# Description: Print formatted header
#######################################
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Bucket Tag Verification Script${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

#######################################
# Function: validate_bucket_exists
# Description: Check if bucket exists
#######################################
validate_bucket_exists() {
    echo -e "${YELLOW}Validating bucket existence...${NC}"

    if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
        echo -e "${GREEN}✓ Bucket '$BUCKET_NAME' exists and is accessible${NC}"
        return 0
    else
        echo -e "${RED}✗ Bucket '$BUCKET_NAME' does not exist or is not accessible${NC}"
        return 1
    fi
}

#######################################
# Function: validate_aws_cli
# Description: Check if AWS CLI is installed
#######################################
validate_aws_cli() {
    echo -e "${YELLOW}Validating AWS CLI installation...${NC}"

    if command -v aws &> /dev/null; then
        AWS_CLI_VERSION=$(aws --version 2>&1)
        echo -e "${GREEN}✓ AWS CLI is installed: $AWS_CLI_VERSION${NC}"
        return 0
    else
        echo -e "${RED}✗ AWS CLI is not installed${NC}"
        echo -e "${RED}  Please install AWS CLI: https://aws.amazon.com/cli/${NC}"
        return 1
    fi
}

#######################################
# Function: get_bucket_tags
# Description: Retrieve all tags from bucket
#######################################
get_bucket_tags() {
    echo -e "${YELLOW}Retrieving bucket tags...${NC}"

    TAGS_JSON=$(aws s3api get-bucket-tagging --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>&1)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully retrieved tags${NC}"
        echo "$TAGS_JSON"
        return 0
    else
        if echo "$TAGS_JSON" | grep -q "NoSuchTagSet"; then
            echo -e "${YELLOW}⚠ Bucket has no tags${NC}"
            return 2
        else
            echo -e "${RED}✗ Error retrieving tags: $TAGS_JSON${NC}"
            return 1
        fi
    fi
}

#######################################
# Function: display_tags
# Description: Parse and display tags in readable format
#######################################
display_tags() {
    local tags_json="$1"

    echo ""
    echo -e "${BLUE}Bucket Tags:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    # Parse JSON and display tags
    echo "$tags_json" | jq -r '.TagSet[] | "\(.Key) = \(.Value)"' 2>/dev/null | while IFS= read -r line; do
        KEY=$(echo "$line" | cut -d'=' -f1 | xargs)
        VALUE=$(echo "$line" | cut -d'=' -f2- | xargs)
        echo -e "${GREEN}  $KEY${NC} : ${YELLOW}$VALUE${NC}"
    done

    # Count tags
    TAG_COUNT=$(echo "$tags_json" | jq '.TagSet | length' 2>/dev/null)
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${BLUE}Total Tags: $TAG_COUNT${NC}"
    echo ""
}

#######################################
# Function: filter_by_tag_key
# Description: Filter and display specific tag by key
#######################################
filter_by_tag_key() {
    local tags_json="$1"
    local search_key="$2"

    echo -e "${YELLOW}Searching for tag key: '$search_key'${NC}"

    TAG_VALUE=$(echo "$tags_json" | jq -r --arg key "$search_key" '.TagSet[] | select(.Key == $key) | .Value' 2>/dev/null)

    if [ -n "$TAG_VALUE" ]; then
        echo -e "${GREEN}✓ Found: $search_key = $TAG_VALUE${NC}"
        return 0
    else
        echo -e "${RED}✗ Tag key '$search_key' not found${NC}"
        return 1
    fi
}

#######################################
# Function: main
# Description: Main execution function
#######################################
main() {
    print_header

    # Check if bucket name is provided
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> [tag-key-to-search]${NC}"
        echo -e "${YELLOW}Example: $0 data-storage-enoch-v13${NC}"
        echo -e "${YELLOW}Example: $0 data-storage-enoch-v13 Environment${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    SEARCH_KEY="$2"

    # Validate AWS CLI is installed
    validate_aws_cli || exit 1

    # Validate bucket exists
    validate_bucket_exists || exit 1

    echo ""

    # Get bucket tags
    TAGS_JSON=$(get_bucket_tags)
    TAG_RESULT=$?

    if [ $TAG_RESULT -eq 0 ]; then
        # Display tags
        display_tags "$TAGS_JSON"

        # If search key provided, filter by it
        if [ -n "$SEARCH_KEY" ]; then
            echo ""
            filter_by_tag_key "$TAGS_JSON" "$SEARCH_KEY"
        fi

        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Tag verification completed successfully${NC}"
        echo -e "${GREEN}========================================${NC}"
        exit 0
    elif [ $TAG_RESULT -eq 2 ]; then
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}  Bucket has no tags to display${NC}"
        echo -e "${YELLOW}========================================${NC}"
        exit 0
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  Tag verification failed${NC}"
        echo -e "${RED}========================================${NC}"
        exit 1
    fi
}

# Execute main function
main "$@"
