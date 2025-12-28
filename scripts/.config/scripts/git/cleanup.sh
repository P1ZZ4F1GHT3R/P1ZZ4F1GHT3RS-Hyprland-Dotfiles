#!/bin/bash

#===============================================================================
# Git Repository Cleanup
# ~/.config/scripts/git/cleanup.sh
# Description: Remove files from git tracking that should be ignored according to .gitignore
# Author: saatvik333
# Version: 2.0
# Dependencies: git
#===============================================================================

set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# --- Functions ---
validate_git_repository() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        die "Not in a git repository!"
    fi
    
    if [[ ! -f .gitignore ]]; then
        die ".gitignore file not found!"
    fi
}

find_ignored_tracked_files() {
    git ls-files -ci --exclude-standard 2>/dev/null || echo ""
}

remove_files_from_tracking() {
    local -r files="$1"
    
    log_info "Removing files from git tracking..."
    
    echo "$files" | while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            log_info "Removing: $file"
            if ! git rm --cached "$file" 2>/dev/null; then
                log_warn "Could not remove: $file"
            fi
        fi
    done
}

show_staged_changes() {
    if git diff --cached --quiet; then
        log_success "No changes to commit."
    else
        log_info "Files removed from tracking. You can now commit these changes:"
        echo
        echo "  git commit -m \"Remove ignored files from tracking\""
        echo
        log_info "Staged changes:"
        git diff --cached --name-only | sed 's/^/  - /'
    fi
}

main() {
    log_info "🧹 Git Repository Cleanup Script"
    echo "================================="
    
    validate_git_repository
    
    log_info "Checking for files that should be ignored..."
    
    local ignored_files
    ignored_files=$(find_ignored_tracked_files)
    
    if [[ -z "$ignored_files" ]]; then
        log_success "No tracked files found that should be ignored!"
        exit 0
    fi
    
    echo
    log_warn "Found the following tracked files that should be ignored:"
    echo "$ignored_files" | sed 's/^/  - /'
    echo
    
    # Ask for confirmation
    read -p "Do you want to remove these files from git tracking? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled."
        exit 0
    fi
    
    remove_files_from_tracking "$ignored_files"
    show_staged_changes
    
    log_success "Cleanup completed!"
    
    # Show current status
    echo
    log_info "Current git status:"
    git status --short
    
    # Send notification
    send_notification "Git Cleanup" "Cleanup Complete" \
        "Removed ignored files from git tracking" "normal" "git"
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi