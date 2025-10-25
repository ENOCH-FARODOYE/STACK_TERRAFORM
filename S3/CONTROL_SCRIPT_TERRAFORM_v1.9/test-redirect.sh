#!/bin/bash

#######################################
# Script: test-redirect.sh
# Purpose: Test S3 bucket redirect functionality
# Story: CONTROL_SCRIPT_TERRAFORM_v1.9
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

#######################################
# Function: print_header
# Description: Print formatted header
#######################################
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Website Redirect Testing${NC}"
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
        echo -e "${GREEN}✓ Bucket '$BUCKET_NAME' exists${NC}"
        return 0
    else
        echo -e "${RED}✗ Bucket '$BUCKET_NAME' not found${NC}"
        return 1
    fi
}

#######################################
# Function: get_redirect_configuration
# Description: Retrieve redirect configuration
#######################################
get_redirect_configuration() {
    echo -e "${YELLOW}Retrieving redirect configuration...${NC}"

    WEBSITE_CONFIG=$(aws s3api get-bucket-website --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>&1)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Redirect configuration found${NC}"
        echo "$WEBSITE_CONFIG"
        return 0
    else
        echo -e "${RED}✗ No website configuration found${NC}"
        return 1
    fi
}

#######################################
# Function: display_redirect_details
# Description: Parse and display redirect details
#######################################
display_redirect_details() {
    local config="$1"

    echo ""
    echo -e "${BLUE}Redirect Configuration:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    # Extract redirect details
    REDIRECT_HOST=$(echo "$config" | jq -r '.RedirectAllRequestsTo.HostName' 2>/dev/null)
    REDIRECT_PROTOCOL=$(echo "$config" | jq -r '.RedirectAllRequestsTo.Protocol' 2>/dev/null)

    if [ "$REDIRECT_HOST" != "null" ]; then
        echo -e "${GREEN}  Redirect Type: All Requests${NC}"
        echo -e "${GREEN}  Target Host: $REDIRECT_HOST${NC}"
        echo -e "${GREEN}  Protocol: $REDIRECT_PROTOCOL${NC}"
        echo -e "${GREEN}  Full Target: ${REDIRECT_PROTOCOL}://${REDIRECT_HOST}${NC}"
    else
        echo -e "${YELLOW}  No redirect configured${NC}"
    fi

    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: get_website_endpoint
# Description: Get S3 website endpoint
#######################################
get_website_endpoint() {
    WEBSITE_ENDPOINT="${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"
    SOURCE_URL="http://${WEBSITE_ENDPOINT}"

    echo ""
    echo -e "${BLUE}Website Endpoint:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${GREEN}  Endpoint: $WEBSITE_ENDPOINT${NC}"
    echo -e "${GREEN}  Source URL: $SOURCE_URL${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: test_redirect_with_curl
# Description: Test redirect using curl
#######################################
test_redirect_with_curl() {
    echo ""
    echo -e "${YELLOW}Testing redirect with curl...${NC}"

    # Test redirect and capture response
    CURL_OUTPUT=$(curl -I -s -L "$SOURCE_URL" 2>&1)
    HTTP_CODE=$(echo "$CURL_OUTPUT" | grep "HTTP/" | head -1 | awk '{print $2}')
    LOCATION=$(echo "$CURL_OUTPUT" | grep -i "location:" | head -1 | awk '{print $2}' | tr -d '\r')

    echo ""
    echo -e "${BLUE}Test Results:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    if [ -n "$HTTP_CODE" ]; then
        if [[ "$HTTP_CODE" == "301" ]]; then
            echo -e "${GREEN}  HTTP Status: $HTTP_CODE (Permanent Redirect)${NC}"
        elif [[ "$HTTP_CODE" == "302" ]]; then
            echo -e "${GREEN}  HTTP Status: $HTTP_CODE (Temporary Redirect)${NC}"
        else
            echo -e "${YELLOW}  HTTP Status: $HTTP_CODE${NC}"
        fi
    else
        echo -e "${RED}  Unable to get HTTP status${NC}"
    fi

    if [ -n "$LOCATION" ]; then
        echo -e "${GREEN}  Redirect Location: $LOCATION${NC}"
    else
        echo -e "${YELLOW}  No redirect location found${NC}"
    fi

    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: test_redirect_detailed
# Description: Detailed redirect test
#######################################
test_redirect_detailed() {
    echo ""
    echo -e "${YELLOW}Performing detailed redirect test...${NC}"

    # Test with different paths
    PATHS=("" "/test" "/page.html" "/folder/file.txt")

    echo ""
    echo -e "${BLUE}Testing Different Paths:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    for PATH in "${PATHS[@]}"; do
        TEST_URL="${SOURCE_URL}${PATH}"

        # Get redirect location
        REDIRECT_LOCATION=$(curl -I -s "$TEST_URL" | grep -i "location:" | head -1 | awk '{print $2}' | tr -d '\r')

        if [ -n "$REDIRECT_LOCATION" ]; then
            echo -e "${GREEN}  $TEST_URL${NC}"
            echo -e "${GREEN}    → $REDIRECT_LOCATION${NC}"
        else
            echo -e "${YELLOW}  $TEST_URL (No redirect)${NC}"
        fi
    done

    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: display_curl_command
# Description: Show curl command for manual testing
#######################################
display_curl_command() {
    echo ""
    echo -e "${BLUE}Manual Testing Command:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${YELLOW}Test the redirect in your terminal:${NC}"
    echo ""
    echo -e "  ${GREEN}curl -I $SOURCE_URL${NC}"
    echo ""
    echo -e "${YELLOW}Or test in browser:${NC}"
    echo -e "  ${GREEN}$SOURCE_URL${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
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
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 redirect-bucket-enoch-v19${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"

    # Validate bucket exists
    validate_bucket_exists || exit 1

    echo ""

    # Get redirect configuration
    WEBSITE_CONFIG=$(get_redirect_configuration)
    CONFIG_RESULT=$?

    if [ $CONFIG_RESULT -eq 0 ]; then
        # Display redirect details
        display_redirect_details "$WEBSITE_CONFIG"

        # Get website endpoint
        get_website_endpoint

        # Test redirect with curl
        test_redirect_with_curl

        # Detailed path testing
        test_redirect_detailed

        # Display manual test command
        display_curl_command

        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Redirect testing completed${NC}"
        echo -e "${GREEN}  Status: REDIRECT CONFIGURED${NC}"
        echo -e "${GREEN}========================================${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  Redirect testing failed${NC}"
        echo -e "${RED}  Status: NO REDIRECT FOUND${NC}"
        echo -e "${RED}========================================${NC}"
        exit 1
    fi
}

# Execute main function
main "$@"
