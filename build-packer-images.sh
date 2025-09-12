#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2025 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory and parent directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}=== Interactive Packer Image Builder (JJB Mode) ===${NC}"
echo "Script location: $SCRIPT_DIR"
echo "Parent directory: $PARENT_DIR"
echo

# Find JJB file
JJB_FILE="$(dirname "$PARENT_DIR")/jjb/releng-packer-jobs.yaml"
if [ ! -f "$JJB_FILE" ]; then
    echo -e "${RED}Error: JJB file not found at $JJB_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Parsing JJB combinations from $JJB_FILE...${NC}"

# Define JJB combinations based on the releng-packer-jobs.yaml file (excluding EOL ubuntu-18.04)
declare -A JJB_COMBINATIONS

# builder platforms
for platform in centos-7 centos-cs-8 centos-cs-9 ubuntu-20.04 ubuntu-22.04 ubuntu-24.04; do
    JJB_COMBINATIONS["$platform,builder"]=1
done

# devstack platforms
JJB_COMBINATIONS["centos-7,devstack"]=1

# devstack-pre-pip variants
for template in devstack-pre-pip-queens devstack-pre-pip-rocky devstack-pre-pip-stein; do
    JJB_COMBINATIONS["centos-7,$template"]=1
done

# docker platforms (excluding ubuntu-18.04 EOL)
for platform in centos-7 ubuntu-20.04 ubuntu-22.04; do
    JJB_COMBINATIONS["$platform,docker"]=1
done

# helm platforms (excluding ubuntu-18.04 EOL)
JJB_COMBINATIONS["centos-7,helm"]=1

# mininet-ovs-217 platforms
for platform in ubuntu-22.04 ubuntu-24.04; do
    JJB_COMBINATIONS["$platform,mininet-ovs-217"]=1
done

# robot platforms
for platform in centos-7 centos-cs-8 centos-cs-9 ubuntu-22.04 ubuntu-24.04; do
    JJB_COMBINATIONS["$platform,robot"]=1
done

echo -e "${GREEN}Found $(( ${#JJB_COMBINATIONS[@]} )) valid JJB combinations (excluding EOL ubuntu-18.04)${NC}"

# Find all variable files and template files for matching
echo -e "${YELLOW}Scanning for variable and template files...${NC}"
mapfile -t VAR_FILES < <(find "$SCRIPT_DIR/vars" -name "*.pkrvars.hcl" ! -name "*cloud-env*" | sort)
mapfile -t TEMPLATE_FILES < <(find "$PARENT_DIR" -name "*.pkr.hcl" -path "*/templates/*" ! -path "*/vars/*" ! -name "variables.auto.pkr.hcl" | sort)

if [ ${#VAR_FILES[@]} -eq 0 ]; then
    echo -e "${RED}Error: No variable files found in $SCRIPT_DIR/vars${NC}"
    exit 1
fi

if [ ${#TEMPLATE_FILES[@]} -eq 0 ]; then
    echo -e "${RED}Error: No template files found${NC}"
    exit 1
fi

# Check for cloud-env.json
CLOUD_ENV_FILE="$PARENT_DIR/cloud-env.json"
if [ ! -f "$CLOUD_ENV_FILE" ]; then
    echo -e "${RED}Error: cloud-env.json not found at $CLOUD_ENV_FILE${NC}"
    echo "Please ensure cloud-env.json exists in the parent directory."
    exit 1
fi

# Create list of valid JJB combinations
echo
echo -e "${GREEN}Valid JJB combinations:${NC}"
valid_combinations=()
for key in "${!JJB_COMBINATIONS[@]}"; do
    platform="${key%,*}"
    template="${key#*,}"

    # Find matching var file
    var_file=""
    for vf in "${VAR_FILES[@]}"; do
        if [[ $(basename "$vf") =~ ^${platform}\.pkrvars\.hcl$ ]]; then
            var_file="$vf"
            break
        fi
    done

    # Find matching template file
    template_file=""
    for tf in "${TEMPLATE_FILES[@]}"; do
        if [[ $(basename "$tf") == "${template}.pkr.hcl" ]]; then
            template_file="$tf"
            break
        fi
    done

    # Add if both files found
    if [[ -n "$var_file" && -n "$template_file" ]]; then
        valid_combinations+=("$platform,$template,$var_file,$template_file")
        rel_var=$(realpath --relative-to="$PARENT_DIR" "$var_file")
        rel_template=$(realpath --relative-to="$PARENT_DIR" "$template_file")
        echo "  $((${#valid_combinations[@]})). $platform + $template ($rel_var + $rel_template)"
    fi
done

if [ ${#valid_combinations[@]} -eq 0 ]; then
    echo -e "${RED}Error: No valid JJB combinations found with available files${NC}"
    exit 1
fi

echo
echo -e "${BLUE}=== Build Options ===${NC}"
echo "1. Build all JJB combinations (${#valid_combinations[@]} builds)"
echo "2. Select specific combinations"
echo "3. Exit"

read -r -p "Choose an option [1-3]: " choice

case $choice in
    1)
        echo -e "${YELLOW}Building all JJB combinations...${NC}"
        selected_combinations=("${valid_combinations[@]}")
        ;;
    2)
        echo -e "${YELLOW}Select specific combinations (space-separated numbers):${NC}"
        for i in "${!valid_combinations[@]}"; do
            combo="${valid_combinations[$i]}"
            platform="${combo%%,*}"
            temp="${combo#*,}"
            template="${temp%%,*}"
            echo "  $((i+1)). $platform + $template"
        done
        read -r -p "Enter numbers: " -a combo_indices
        selected_combinations=()
        for idx in "${combo_indices[@]}"; do
            if [[ $idx =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le ${#valid_combinations[@]} ]; then
                selected_combinations+=("${valid_combinations[$((idx-1))]}")
            fi
        done
        ;;
    3)
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

if [ ${#selected_combinations[@]} -eq 0 ]; then
    echo -e "${RED}No valid combinations selected. Exiting.${NC}"
    exit 1
fi
echo
echo -e "${GREEN}Selected JJB combinations:${NC}"
for combo in "${selected_combinations[@]}"; do
    platform="${combo%%,*}"
    temp="${combo#*,}"
    template="${temp%%,*}"
    echo "  - $platform + $template"
done

total_builds=${#selected_combinations[@]}
echo -e "${BLUE}Total builds to execute: $total_builds${NC}"
echo

# Ask for execution mode
echo -e "${BLUE}=== Execution Options ===${NC}"
echo "1. Execute builds immediately"
echo "2. Generate build commands only (dry-run)"
echo "3. Execute builds in background"

read -r -p "Choose execution mode [1-3]: " exec_mode

# Generate and optionally execute build commands
build_count=0
cd "$PARENT_DIR"

for combo in "${selected_combinations[@]}"; do
    build_count=$((build_count + 1))

    # Parse combination string: "platform,template,var_file,template_file"
    platform="${combo%%,*}"
    temp="${combo#*,}"
    template="${temp%%,*}"
    temp2="${temp#*,}"
    var_file="${temp2%%,*}"
    template_file="${temp2#*,}"

    # Convert absolute paths to relative paths from parent directory
    rel_var_path=$(realpath --relative-to="$PARENT_DIR" "$var_file")
    rel_template_path=$(realpath --relative-to="$PARENT_DIR" "$template_file")
    rel_cloud_env_path=$(realpath --relative-to="$PARENT_DIR" "$CLOUD_ENV_FILE")

    # Determine build target based on template name
    template_basename=$(basename "$rel_template_path" .pkr.hcl)
    build_target="openstack.$template_basename"

    # Create log file name with timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")
    log_file="/tmp/packer-build-${platform}-${template}-${timestamp}.log"

    build_cmd="OS_CLOUD=odlci packer.io build -only=\"$build_target\" -var-file=\"$rel_cloud_env_path\" -var-file=\"$rel_var_path\" -var \"local_build=true\" \"$rel_template_path\""

    echo -e "${YELLOW}[$build_count/$total_builds] $platform + $template${NC}"
    echo "  $build_cmd"
    echo "  Log file: $log_file"

    case $exec_mode in
        1)
            echo -e "${BLUE}Executing build $build_count/$total_builds...${NC}"
            eval "$build_cmd" 2>&1 | tee "$log_file"
            build_status=${PIPESTATUS[0]}
            if [ "$build_status" -eq 0 ]; then
                echo -e "${GREEN}Build $build_count completed successfully${NC}"
                echo "  Log saved to: $log_file"
            else
                echo -e "${RED}Build $build_count failed (exit code: $build_status)${NC}"
                echo "  Error log saved to: $log_file"
            fi
            echo
            ;;
        2)
            # Dry-run mode, just show commands
            echo "  Would log to: $log_file"
            ;;
        3)
            echo -e "${BLUE}Starting background build $build_count/$total_builds...${NC}"
            eval "$build_cmd" > "$log_file" 2>&1 &
            bg_pid=$!
            echo -e "${GREEN}Background build $build_count started with PID $bg_pid${NC}"
            echo "  Log file: $log_file"
            ;;
    esac
done

case $exec_mode in
    1)
        echo -e "${GREEN}All $total_builds builds completed!${NC}"
        echo -e "${YELLOW}Build logs saved to /tmp/packer-build-*.log${NC}"
        ;;
    2)
        echo -e "${GREEN}Generated $total_builds build commands (dry-run mode)${NC}"
        echo -e "${YELLOW}Logs would be saved to /tmp/packer-build-*.log${NC}"
        ;;
    3)
        echo -e "${GREEN}Started $total_builds background builds${NC}"
        echo -e "${YELLOW}Individual logs being written to /tmp/packer-build-*.log${NC}"
        echo -e "${YELLOW}Use 'jobs' to monitor background processes${NC}"
        echo -e "${YELLOW}Use 'wait' to wait for all background jobs to complete${NC}"
        echo -e "${YELLOW}Use 'tail -f /tmp/packer-build-*.log' to monitor progress${NC}"
        ;;
esac