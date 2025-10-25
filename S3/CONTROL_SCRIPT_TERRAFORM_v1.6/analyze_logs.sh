

#!/bin/bash

#######################################
# Script: analyze-logs.sh
# Purpose: Analyze S3 server access logs
# Story: CONTROL_SCRIPT_TERRAFORM_v1.6
#######################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_BUCKET=""
LOG_PREFIX=""
AWS_REGION="us-east-1"
TEMP_DIR="/tmp/s3-logs-$$"

#######################################
# Function: print_header
# Description: Print formatted header
#######################################
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Access Log Analysis${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

#######################################
# Function: download_logs
# Description: Download log files for analysis
#######################################
download_logs() {
    echo -e "${YELLOW}Downloading log files...${NC}"

    mkdir -p "$TEMP_DIR"

    # Download recent logs (last 100 files)
    aws s3 sync "s3://$LOG_BUCKET/$LOG_PREFIX" "$TEMP_DIR" --region "$AWS_REGION" --quiet

    LOG_FILE_COUNT=$(ls -1 "$TEMP_DIR" 2>/dev/null | wc -l)

    if [ "$LOG_FILE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Downloaded $LOG_FILE_COUNT log file(s)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ No log files found to download${NC}"
        return 1
    fi
}

#######################################
# Function: analyze_operations
# Description: Analyze operations from logs
#######################################
analyze_operations() {
    echo ""
    echo -e "${BLUE}Operation Analysis:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    # Count operations
    GET_COUNT=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $8}' | grep -c "GET" || echo 0)
    PUT_COUNT=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $8}' | grep -c "PUT" || echo 0)
    DELETE_COUNT=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $8}' | grep -c "DELETE" || echo 0)
    HEAD_COUNT=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $8}' | grep -c "HEAD" || echo 0)
    LIST_COUNT=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $8}' | grep -c "LIST" || echo 0)

    echo -e "${GREEN}  GET operations: $GET_COUNT${NC}"
    echo -e "${GREEN}  PUT operations: $PUT_COUNT${NC}"
    echo -e "${GREEN}  DELETE operations: $DELETE_COUNT${NC}"
    echo -e "${GREEN}  HEAD operations: $HEAD_COUNT${NC}"
    echo -e "${GREEN}  LIST operations: $LIST_COUNT${NC}"

    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: analyze_status_codes
# Description: Analyze HTTP status codes
#######################################
analyze_status_codes() {
    echo ""
    echo -e "${BLUE}HTTP Status Code Analysis:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    # Count status codes
    STATUS_200=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $9}' | grep -c "^200$" || echo 0)
    STATUS_204=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $9}' | grep -c "^204$" || echo 0)
    STATUS_403=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $9}' | grep -c "^403$" || echo 0)
    STATUS_404=$(cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $9}' | grep -c "^404$" || echo 0)

    echo -e "${GREEN}  200 (Success): $STATUS_200${NC}"
    echo -e "${GREEN}  204 (No Content): $STATUS_204${NC}"
    if [ "$STATUS_403" -gt 0 ]; then
        echo -e "${RED}  403 (Forbidden): $STATUS_403${NC}"
    fi
    if [ "$STATUS_404" -gt 0 ]; then
        echo -e "${YELLOW}  404 (Not Found): $STATUS_404${NC}"
    fi

    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: analyze_requesters
# Description: Analyze top requesters
#######################################
analyze_requesters() {
    echo ""
    echo -e "${BLUE}Top 5 Requesters (by IP):${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    cat "$TEMP_DIR"/* 2>/dev/null | awk '{print $5}' | sort | uniq -c | sort -rn | head -5 | while read count ip; do
        echo -e "${GREEN}  $ip: $count requests${NC}"
    done

    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: display_log_format
# Description: Show S3 log format explanation
#######################################
display_log_format() {
    echo ""
    echo -e "${BLUE}S3 Access Log Format:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${YELLOW}Each log entry contains:${NC}"
    echo -e "  1. Bucket Owner"
    echo -e "  2. Bucket Name"
    echo -e "  3. Request Date/Time"
    echo -e "  4. Remote IP"
    echo -e "  5. Requester"
    echo -e "  6. Request ID"
    echo -e "  7. Operation"
    echo -e "  8. Object Key"
    echo -e "  9. HTTP Status"
    echo -e "  10. Error Code"
    echo -e "  And more..."
    echo -e "${BLUE}----------------------------------------${NC}"
}

#######################################
# Function: cleanup
# Description: Clean up temporary files
#######################################
cleanup() {
    rm -rf "$TEMP_DIR"
}

#######################################
# Function: main
# Description: Main execution function
#######################################
main() {
    print_header

    # Check if arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Log bucket and prefix are required${NC}"
        echo -e "${YELLOW}Usage: $0 <log-bucket-name> <log-prefix>${NC}"
        echo -e "${YELLOW}Example: $0 logs-storage-enoch-v16 logs/access/${NC}"
        exit 1
    fi

    LOG_BUCKET="$1"
    LOG_PREFIX="$2"

    # Download logs
    if download_logs; then
        # Analyze logs
        analyze_operations
        analyze_status_codes
        analyze_requesters
        display_log_format

        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Log analysis completed${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo ""
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${YELLOW}  No logs available for analysis${NC}"
        echo -e "${YELLOW}  Wait 5-15 minutes after bucket activity${NC}"
        echo -e "${YELLOW}========================================${NC}"
    fi

    # Cleanup
    cleanup
}

# Trap cleanup on exit
trap cleanup EXIT

# Execute main function
main "$@"
