#!/bin/bash

#===============================================================================
# GitIgnore Validation
# ~/.config/scripts/git/validate-gitignore.sh
# Description: Validate and analyze .gitignore file effectiveness
# Author: saatvik333
# Version: 2.0
# Dependencies: git, find
#===============================================================================

set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# --- Configuration ---
readonly COMMON_PATTERNS=(
    "*.log" "*.tmp" "*.cache" "*.pid" "*.lock"
    ".DS_Store" "Thumbs.db" "*.swp" "*.swo" "*~"
    "*.bak" "*.backup" "node_modules/" ".env"
    "__pycache__/" "*.pyc"
)

readonly SENSITIVE_PATTERNS=(
    "*.key" "*.pem" "*.p12" "*.pfx"
    "*password*" "*secret*" "*.env"
    "config.json" "credentials*"
)

# --- Functions ---
validate_git_repository() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        die "Not in a git repository!"
    fi
    
    if [[ ! -f .gitignore ]]; then
        die ".gitignore file not found!"
    fi
}

check_ignored_tracked_files() {
    log_info "Checking for tracked files that should be ignored..."
    
    local ignored_tracked
    ignored_tracked=$(git ls-files -ci --exclude-standard 2>/dev/null || echo "")
    
    if [[ -n "$ignored_tracked" ]]; then
        log_warn "Found tracked files that should be ignored:"
        echo "$ignored_tracked" | sed 's/^/  - /'
        echo
        return 1
    else
        log_success "No tracked files found that should be ignored."
        return 0
    fi
}

check_missing_common_patterns() {
    log_info "Checking for common ignore patterns..."
    
    local missing_patterns=()
    
    for pattern in "${COMMON_PATTERNS[@]}"; do
        if ! grep -q "^${pattern//\*/\\*}$" .gitignore 2>/dev/null; then
            # Check if there are files matching this pattern
            if find . -name "$pattern" -type f 2>/dev/null | head -1 | grep -q .; then
                missing_patterns+=("$pattern")
            fi
        fi
    done
    
    if [[ ${#missing_patterns[@]} -gt 0 ]]; then
        log_warn "Consider adding these common patterns to .gitignore:"
        for pattern in "${missing_patterns[@]}"; do
            echo "  - $pattern"
        done
        echo
        return 1
    fi
    
    return 0
}

check_large_files() {
    log_info "Checking for large files (>1MB) that might need to be ignored..."
    
    local large_files
    large_files=$(find . -type f -size +1M 2>/dev/null | grep -v "^\./.git/" | head -10)
    
    if [[ -n "$large_files" ]]; then
        log_warn "Found large files that might need to be ignored:"
        echo "$large_files" | while read -r file; do
            local size
            size=$(du -h "$file" 2>/dev/null | cut -f1)
            echo "  - $file ($size)"
        done
        echo
        return 1
    fi
    
    return 0
}

check_sensitive_files() {
    log_info "Checking for potentially sensitive files..."
    
    local sensitive_files=()
    
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        while IFS= read -r -d '' file; do
            if [[ -f "$file" ]] && ! git check-ignore "$file" >/dev/null 2>&1; then
                sensitive_files+=("$file")
            fi
        done < <(find . -name "$pattern" -type f -print0 2>/dev/null)
    done
    
    if [[ ${#sensitive_files[@]} -gt 0 ]]; then
        log_warn "Found potentially sensitive files that should be ignored:"
        for file in "${sensitive_files[@]}"; do
            echo "  - $file"
        done
        echo
        return 1
    fi
    
    return 0
}

show_gitignore_statistics() {
    local total_patterns comment_lines total_lines
    
    total_patterns=$(grep -c "^[^#]" .gitignore 2>/dev/null || echo "0")
    comment_lines=$(grep -c "^#" .gitignore 2>/dev/null || echo "0")
    total_lines=$(wc -l < .gitignore)
    
    log_info ".gitignore Statistics:"
    echo "  - Total ignore patterns: $total_patterns"
    echo "  - Comment lines: $comment_lines"
    echo "  - Total lines: $total_lines"
}

main() {
    log_info "🔍 GitIgnore Validation Script"
    echo "=============================="
    
    validate_git_repository
    
    log_info "Validating .gitignore patterns..."
    
    local issues=0
    
    # Run all checks
    check_ignored_tracked_files || ((issues++))
    check_missing_common_patterns || ((issues++))
    check_large_files || ((issues++))
    check_sensitive_files || ((issues++))
    
    # Summary
    echo "================================"
    log_info "Validation Summary:"
    
    if [[ $issues -eq 0 ]]; then
        log_success "Your .gitignore appears to be well configured!"
        send_notification "Git Validation" "GitIgnore Validation Complete" \
            "No issues found - .gitignore is well configured!" "normal" "git"
    else
        log_warn "Consider reviewing the warnings above to improve your .gitignore."
        send_notification "Git Validation" "GitIgnore Issues Found" \
            "$issues potential issues found in .gitignore" "normal" "git"
    fi
    
    echo
    show_gitignore_statistics
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi