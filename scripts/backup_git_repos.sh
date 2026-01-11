#!/bin/bash

set -e

# Global variables
REPOS=()
SUCCESS=0
FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if curl is available
check_curl_installed() {
    if ! command -v curl &>/dev/null; then
        print_error "curl is not installed. Please install curl to continue."
        exit 1
    fi
}

# Check if GITHUB_TOKEN is set
check_github_token() {
    if [ -z "$GITHUB_TOKEN" ]; then
        print_error "GITHUB_TOKEN environment variable is not set. Please set it to access private repositories."
        exit 1
    fi
}

# Validate command line arguments
validate_arguments() {
    if [ $# -lt 2 ]; then
        print_error "Missing required arguments"
        echo "Usage: $0 <GITHUB_PROFILE_NAME> <TARGET_DIRECTORY>"
        echo ""
        echo "Required Arguments:"
        echo "  GITHUB_PROFILE_NAME: The GitHub profile/username to clone repositories from"
        echo "  TARGET_DIRECTORY: The directory where repositories will be cloned"
        exit 1
    fi

    GITHUB_USERNAME="$1"
    TARGET_DIR="$2"

    # Validate GITHUB_PROFILE_NAME is not empty
    if [ -z "$GITHUB_USERNAME" ]; then
        print_error "GITHUB_PROFILE_NAME is required and cannot be empty"
        exit 1
    fi

    # Validate TARGET_DIRECTORY is not empty
    if [ -z "$TARGET_DIR" ]; then
        print_error "TARGET_DIRECTORY is required and cannot be empty"
        exit 1
    fi
}

# Create target directory if it doesn't exist
setup_target_directory() {
    local target_dir="$1"

    if [ ! -d "$target_dir" ]; then
        print_info "Creating target directory: $target_dir"
        mkdir -p "$target_dir"
    else
        print_info "Using existing target directory: $target_dir"
    fi
}

# Fetch all repositories from GitHub using the API
fetch_repositories() {
    local github_username="$1"

    print_info "Fetching repositories for GitHub user: $github_username"

    # Fetch all repositories (public and private) using GitHub API
    # Using pagination to get all repositories (100 per page)
    local page=1
    local per_page=100

    while true; do
        local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/users/$github_username/repos?type=all&per_page=$per_page&page=$page&sort=updated")

        # Check if response contains any repositories
        if [ "$(echo "$response" | grep -c '"name"')" -eq 0 ]; then
            break
        fi

        # Extract repository SSH URLs
        local page_repos=$(echo "$response" | grep -o 'ssh_url[^,]*' | sed 's/ssh_url": "\(.*\)".*/\1/')

        while IFS= read -r repo_url; do
            if [ -n "$repo_url" ]; then
                REPOS+=("$repo_url")
            fi
        done <<<"$page_repos"

        page=$((page + 1))
    done
}

# Validate that repositories were found
validate_repositories_found() {
    if [ ${#REPOS[@]} -eq 0 ]; then
        print_error "No repositories found for user: $GITHUB_USERNAME"
        exit 1
    fi

    print_success "Found ${#REPOS[@]} repositories"
    echo ""
}

# Extract git username and repo name from SSH URL
# SSH URL format: git@github.com:username/repo.git
extract_git_info() {
    local repo_url="$1"
    # Remove the git@github.com: prefix and .git suffix, then split on /
    local path="${repo_url#*:}"     # Remove git@github.com: prefix
    path="${path%.git}"             # Remove .git suffix
    local git_username="${path%%/*}" # Get username (part before /)
    local repo_name="${path##*/}"    # Get repo name (part after /)

    echo "$git_username|$repo_name"
}

# Clone a single repository
clone_single_repository() {
    local repo_url="$1"
    local target_dir="$2"

    # Extract git username and repo name from SSH URL
    local git_info=$(extract_git_info "$repo_url")
    local git_username="${git_info%|*}"
    local repo_name="${git_info#*|}"

    local repo_path="$target_dir/$git_username/$repo_name"

    # Ensure the username directory exists
    mkdir -p "$target_dir/$git_username"

    # Check if repository already exists
    if [ -d "$repo_path" ]; then
        print_info "Repository already exists at $repo_path, updating via git pull..."

        if (cd "$repo_path" && git pull >/dev/null 2>&1); then
            print_success "✓ Successfully updated: $repo_name"
        else
            print_error "⚠ Failed to update: $repo_name (continuing anyway)"
        fi
        return 0
    fi

    print_info "Cloning: $repo_url"

    if git clone "$repo_url" "$repo_path" >/dev/null 2>&1; then
        print_success "✓ Successfully cloned: $repo_name"
        return 0
    else
        print_error "✗ Failed to clone: $repo_name"
        return 1
    fi
}

# Clone all repositories
clone_all_repositories() {
    local target_dir="$1"

    for repo_url in "${REPOS[@]}"; do
        if clone_single_repository "$repo_url" "$target_dir"; then
            SUCCESS=$((SUCCESS + 1))
        else
            FAILED=$((FAILED + 1))
        fi
    done
}

# Print summary of clone operation
print_clone_summary() {
    local target_dir="$1"

    echo ""
    print_success "Clone operation completed!"
    echo "  Successful: $SUCCESS"
    echo "  Failed: $FAILED"
    echo "  Total repositories: ${#REPOS[@]}"
    echo ""
    print_info "All repositories cloned to: $target_dir"
}

# Main function to orchestrate the script execution
main() {
    # Pre-flight checks
    check_curl_installed
    check_github_token
    validate_arguments "$@"

    # Setup
    setup_target_directory "$TARGET_DIR"

    # Fetch and process repositories
    fetch_repositories "$GITHUB_USERNAME"
    validate_repositories_found

    # Clone repositories
    clone_all_repositories "$TARGET_DIR"

    # Summary and exit
    print_clone_summary "$TARGET_DIR"

    if [ $FAILED -gt 0 ]; then
        exit 1
    fi

    exit 0
}

# Execute main function with all arguments
main "$@"
