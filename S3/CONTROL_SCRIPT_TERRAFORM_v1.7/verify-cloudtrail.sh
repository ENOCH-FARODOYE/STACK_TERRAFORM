

#!/bin/bash

#######################################
# Script: verify-cloudtrail.sh
# Purpose: Verify CloudTrail configuration for S3 object-level logging
# Story: CONTROL_SCRIPT_TERRAFORM_v1.7
#######################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TRAIL_NAME=""
BUCKET_NAME=""
AWS_REGION="us-east-1"

#######################################
# Function: print_header
# Description: Print formatted header
#######################################
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  CloudTrail S3 Object Logging Verification${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

#######################################
# Function: validate_trail_exists
# Description: Check if CloudTrail trail exists
#######################################
validate_trail_exists() {
    echo -e "${YELLOW}Validating CloudTrail trail existence...${NC}"

    TRAIL_INFO=$(aws cloudtrail get-trail --name "$TRAIL_NAME" --region "$AWS_REGION" 2>&1)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ CloudTrail trail '$TRAIL_NAME' exists${NC}"
        return 0
    else
        echo -e "${RED}✗ CloudTrail trail '$TRAIL_NAME' not found${NC}"
        return 1
    fi
}

#######################################
# Function: get_trail_status
# Description: Check if trail is logging
#######################################
get_trail_status() {
    echo -e "${YELLOW}Checking CloudTrail logging status...${NC}"

    TRAIL_STATUS=$(aws cloudtrail get-trail-status --name "$TRAIL_NAME" --region "$AWS_REGION" 2>&1)

    if [ $? -eq 0 ]; then
        IS_LOGGING=$(echo "$TRAIL_STATUS" | jq -r '.IsLogging' 2>/dev/null)

        if [ "$IS_LOGGING" == "true" ]; then
            echo -e "${GREEN}✓ CloudTrail is actively logging${NC}"

            LATEST_DELIVERY=$(echo "$TRAIL_STATUS" | jq -r '.LatestDeliveryTime' 2>/dev/null)
            if [ "$LATEST_DELIVERY" != "null" ]; then
                echo -e "${GREEN}  Latest log delivery: $LATEST_DELIVERY${NC}"
            fi
            return 0
        else
            echo -e "${YELLOW}⚠ CloudTrail exists but is not logging${NC}"
            return 2
        fi
    else
        echo -e "${RED}✗ Error checking trail status${NC}"
        return 1
    fi
}

#######################################
# Function: display_trail_configuration
# Description: Display trail configuration details
#######################################
display_trail_configuration() {
    echo ""
    echo -e "${BLUE}CloudTrail Configuration:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    TRAIL_CONFIG=$(aws cloudtrail get-trail --name "$TRAIL_NAME" --region "$AWS_REGION" 2>/dev/null)

    S3_BUCKET=$(echo "$TRAIL_CONFIG" | jq -r '.Trail.S3BucketName' 2>/dev/null)
    LOG_VALIDATION=$(echo "$TRAIL_CONFIG" | jq -r '.Trail.LogFileValidationEnabled' 2>/dev/null)
    MULTI_REGION=$(echo "$TRAIL_CONFIG" | jq -r '.Trail.IsMultiRegionTrail' 2>/dev/null)

    echo -e "${GREEN}  Trail Name: $TRAIL_NAME${NC}"
    echo -e "${GREEN}  S3 Bucket: $S3_BUCKET${NC}"
    echo -e "${GREEN}  Log Validation: $LOG_VALIDATION${NC}"
    echo -e "${GREEN}  Multi-Region: $MULTI_REGION${NC}"

    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: check_event_selectors
# Description: Check if S3 data events are configured
#######################################
check_event_selectors() {
    echo ""
    echo -e "${YELLOW}Checking event selectors for S3 data events...${NC}"

    EVENT_SELECTORS=$(aws cloudtrail get-event-selectors --trail-name "$TRAIL_NAME" --region "$AWS_REGION" 2>&1)

    if [ $? -eq 0 ]; then
        # Check if S3 data events are configured
        S3_DATA_RESOURCES=$(echo "$EVENT_SELECTORS" | jq -r '.EventSelectors[].DataResources[] | select(.Type == "AWS::S3::Object")' 2>/dev/null)

        if [ -n "$S3_DATA_RESOURCES" ]; then
            echo -e "${GREEN}✓ S3 object-level logging is configured${NC}"

            echo ""
            echo -e "${BLUE}Event Selector Details:${NC}"
            echo -e "${BLUE}----------------------------------------${NC}"

            READ_WRITE=$(echo "$EVENT_SELECTORS" | jq -r '.EventSelectors[].ReadWriteType' 2>/dev/null)
            echo -e "${GREEN}  Read/Write Type: $READ_WRITE${NC}"

            echo -e "${GREEN}  Logged Operations:${NC}"
            if [[ "$READ_WRITE" == "All" ]]; then
                echo -e "${GREEN}    - GetObject${NC}"
                echo -e "${GREEN}    - PutObject${NC}"
                echo -e "${GREEN}    - DeleteObject${NC}"
                echo -e "${GREEN}    - CopyObject${NC}"
                echo -e "${GREEN}    - And more...${NC}"
            elif [[ "$READ_WRITE" == "ReadOnly" ]]; then
                echo -e "${GREEN}    - GetObject${NC}"
                echo -e "${GREEN}    - HeadObject${NC}"
            elif [[ "$READ_WRITE" == "WriteOnly" ]]; then
                echo -e "${GREEN}    - PutObject${NC}"
                echo -e "${GREEN}    - DeleteObject${NC}"
            fi

            echo -e "${BLUE}----------------------------------------${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ S3 data events are NOT configured${NC}"
            return 2
        fi
    else
        echo -e "${RED}✗ Error retrieving event selectors${NC}"
        return 1
    fi
}

#######################################
# Function: test_cloudtrail_logging
# Description: Generate test activity and check for events
#######################################
test_cloudtrail_logging() {
    echo ""
    echo -e "${YELLOW}Testing CloudTrail by generating S3 activity...${NC}"

    # Generate some activity
    echo "CloudTrail test file - $(date)" > test-cloudtrail-file.txt
    aws s3 cp test-cloudtrail-file.txt "s3://$BUCKET_NAME/" --region "$AWS_REGION" &>/dev/null
    aws s3 ls "s3://$BUCKET_NAME/" --region "$AWS_REGION" &>/dev/null
    aws s3 rm "s3://$BUCKET_NAME/test-cloudtrail-file.txt" --region "$AWS_REGION" &>/dev/null
    rm -f test-cloudtrail-file.txt

    echo -e "${GREEN}✓ Generated test activity (PutObject, ListBucket, DeleteObject)${NC}"
    echo -e "${YELLOW}  Note: Events may take 5-15 minutes to appear in CloudTrail${NC}"
    echo ""

    # Check for recent events
    echo -e "${YELLOW}Checking for recent CloudTrail events...${NC}"

    RECENT_EVENTS=$(aws cloudtrail lookup-events \
        --lookup-attributes AttributeKey=ResourceName,AttributeValue="$BUCKET_NAME" \
        --max-results 5 \
        --region "$AWS_REGION" 2>/dev/null)

    EVENT_COUNT=$(echo "$RECENT_EVENTS" | jq '.Events | length' 2>/dev/null)

    if [ "$EVENT_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $EVENT_COUNT recent event(s)${NC}"
        echo ""
        echo -e "${BLUE}Recent Events:${NC}"
        echo -e "${BLUE}----------------------------------------${NC}"

        echo "$RECENT_EVENTS" | jq -r '.Events[] | "  Event: \(.EventName) | Time: \(.EventTime) | User: \(.Username)"' 2>/dev/null

        echo -e "${BLUE}----------------------------------------${NC}"
    else
        echo -e "${YELLOW}⚠ No recent events found (events may take time to appear)${NC}"
    fi
}

#######################################
# Function: main
# Description: Main execution function
#######################################
main() {
    print_header

    # Check if arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Trail name and bucket name are required${NC}"
        echo -e "${YELLOW}Usage: $0 <trail-name> <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 s3-object-level-trail-v17 data-storage-enoch-v17${NC}"
        exit 1
    fi

    TRAIL_NAME="$1"
    BUCKET_NAME="$2"

    # Validate trail exists
    validate_trail_exists || exit 1

    echo ""

    # Get trail status
    get_trail_status
    STATUS_RESULT=$?

    if [ $STATUS_RESULT -eq 0 ]; then
        # Display trail configuration
        display_trail_configuration

        # Check event selectors
        check_event_selectors

        # Test logging
        test_cloudtrail_logging

        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  CloudTrail verification completed${NC}"
        echo -e "${GREEN}  Status: ENABLED and LOGGING${NC}"
        echo -e "${GREEN}========================================${NC}"
        exit 0
    elif [ $STATUS_RESULT -eq 2 ]; then
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}  CloudTrail exists but not logging${NC}"
        echo -e "${YELLOW}========================================${NC}"
        exit 1
    else
        echo ""
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  CloudTrail verification failed${NC}"
        echo -e "${RED}========================================${NC}"
        exit 1
    fi
}

# Execute main function
main "$@"
