

#!/bin/bash

#######################################
# Script: verify-logging.sh
# Purpose: Verify S3 bucket logging configuration
# Story: CONTROL_SCRIPT_TERRAFORM_v1.6
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
    echo -e "${BLUE}  S3 Server Access Logging Verification${NC}"
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
# Function: get_logging_configuration
# Description: Retrieve logging configuration
#######################################
get_logging_configuration() {
    echo -e "${YELLOW}Retrieving logging configuration...${NC}"

    LOGGING_JSON=$(aws s3api get-bucket-logging --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>&1)

    if [ $? -eq 0 ]; then
        # Check if logging is actually configured
        if echo "$LOGGING_JSON" | jq -e '.LoggingEnabled' > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Logging is configured and enabled${NC}"
            echo "$LOGGING_JSON"
            return 0
        else
            echo -e "${YELLOW}⚠ Logging configuration exists but is empty${NC}"
            return 2
        fi
    else
        echo -e "${RED}✗ Error retrieving logging configuration${NC}"
        return 1
    fi
}

#######################################
# Function: display_logging_config
# Description: Parse and display logging details
#######################################
display_logging_config() {
    local logging_json="$1"

    echo ""
    echo -e "${BLUE}Logging Configuration:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    # Extract target bucket
    TARGET_BUCKET=$(echo "$logging_json" | jq -r '.LoggingEnabled.TargetBucket' 2>/dev/null)
    TARGET_PREFIX=$(echo "$logging_json" | jq -r '.LoggingEnabled.TargetPrefix' 2>/dev/null)

    echo -e "${GREEN}  Target Bucket: $TARGET_BUCKET${NC}"
    echo -e "${GREEN}  Target Prefix: $TARGET_PREFIX${NC}"
    echo -e "${GREEN}  Log Location: s3://$TARGET_BUCKET/$TARGET_PREFIX${NC}"

    echo -e "${BLUE}----------------------------------------${NC}"
    echo ""
}

#######################################
# Function: check_log_destination
# Description: Verify log destination bucket exists
#######################################
check_log_destination() {
    local target_bucket="$1"

    echo -e "${YELLOW}Verifying log destination bucket...${NC}"

    if aws s3api head-bucket --bucket "$target_bucket" --region "$AWS_REGION" 2>/dev/null; then
        echo -e "${GREEN}✓ Log destination bucket '$target_bucket' exists${NC}"
        return 0
    else
        echo -e "${RED}✗ Log destination bucket '$target_bucket' does not exist${NC}"
        return 1
    fi
}

#######################################
# Function: test_logging
# Description: Generate test activity and check for logs
#######################################
test_logging() {
    local target_bucket="$1"
    local target_prefix="$2"

    echo -e "${YELLOW}Testing logging by generating bucket activity...${NC}"

    # Generate some activity
    echo "test" > test-logging-file.txt
    aws s3 cp test-logging-file.txt "s3://$BUCKET_NAME/" --region "$AWS_REGION" &>/dev/null
    aws s3 ls "s3://$BUCKET_NAME/" --region "$AWS_REGION" &>/dev/null
    aws s3 rm "s3://$BUCKET_NAME/test-logging-file.txt" --region "$AWS_REGION" &>/dev/null
    rm -f test-logging-file.txt

    echo -e "${GREEN}✓ Generated test activity (upload, list, delete)${NC}"
    echo -e "${YELLOW}  Note: Logs may take 5-15 minutes to appear${NC}"
    echo ""

    # Check if any logs exist
    echo -e "${YELLOW}Checking for existing log files...${NC}"

    LOG_COUNT=$(aws s3 ls "s3://$target_bucket/$target_prefix" --region "$AWS_REGION" --recursive 2>/dev/null | wc -l)

    if [ "$LOG_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $LOG_COUNT log file(s) in destination${NC}"
        echo ""
        echo -e "${BLUE}Recent log files:${NC}"
        aws s3 ls "s3://$target_bucket/$target_prefix" --region "$AWS_REGION" --recursive | tail -5
    else
        echo -e "${YELLOW}⚠ No log files found yet (logs may take time to generate)${NC}"
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
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 data-storage-enoch-v16${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"

    # Validate bucket exists
    validate_bucket_exists || exit 1

    echo ""

    # Get logging configuration
    LOGGING_JSON=$(get_logging_configuration)
    LOGGING_RESULT=$?

    if [ $LOGGING_RESULT -eq 0 ]; then
        # Display logging configuration
        display_logging_config "$LOGGING_JSON"

        # Extract target bucket and prefix
        TARGET_BUCKET=$(echo "$LOGGING_JSON" | jq -r '.LoggingEnabled.TargetBucket' 2>/dev/null)
        TARGET_PREFIX=$(echo "$LOGGING_JSON" | jq -r '.LoggingEnabled.TargetPrefix' 2>/dev/null)

        # Check log destination exists
        check_log_destination "$TARGET_BUCKET"

        echo ""

        # Test logging by generating activity
        test_logging "$TARGET_BUCKET" "$TARGET_PREFIX"

        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Logging verification completed${NC}"
        echo -e "${GREEN}  Status: ENABLED and CONFIGURED${NC}"
        echo -e "${GREEN}========================================${NC}"
        exit 0
    elif [ $LOGGING_RESULT -eq 2 ]; then
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}  Logging NOT configured${NC}"
        echo -e "${YELLOW}  Status: DISABLED${NC}"
        echo -e "${YELLOW}========================================${NC}"
        exit 1
    else
        echo ""
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  Logging verification failed${NC}"
        echo -e "${RED}========================================${NC}"
        exit 1
    fi
}

# Execute main function
main "$@"
