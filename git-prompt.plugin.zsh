# Git prompt with tooltips plugin
# Author: Numan Syed
# License: MIT
# Version: 1.0.0

# Enable necessary zsh features
setopt PROMPT_SUBST

# Function to add tooltip trigger to git prompt
function add_tooltip_trigger() {
    local content=$1
    local tooltip=$2
    # Using standard OSC 8 with empty URL but tooltip content
    if [[ "$TERM_PROGRAM" == "vscode" ]]; then
        # VSCode terminal format
        echo "%{\e]8;;${tooltip}\a%}${content}%{\e]8;;\a%}"
    else
        # Standard terminal format (using \033 instead of \e)
        echo "%{\033]8;;${tooltip}\007%}${content}%{\033]8;;\007%}"
    fi
}

# Git prompt function with tooltip
__git_prompt() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        # Get current action (rebase/merge)
        local git_dir=$(git rev-parse --git-dir)
        local action=""
        if [[ -d "$git_dir/rebase-merge" ]]; then
            action="REBASING"
        elif [[ -d "$git_dir/rebase-apply" ]]; then
            action="REBASING"
        elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
            action="MERGING"
        elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
            action="CHERRY-PICKING"
        fi

        # Get branch or SHA if in detached HEAD
        local branch=""
        if git symbolic-ref -q HEAD >/dev/null 2>&1; then
            branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        else
            branch="➦ $(git rev-parse --short HEAD)"
        fi

        local git_status=$(git status --porcelain 2>/dev/null)
        local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
        local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
        local stash_count=$(git stash list | wc -l | tr -d '[:space:]')
        
        # Build the branch tooltip
        local branch_tooltip=""
        # Build branch tooltip - keep it simple with just the branch name
        branch_tooltip=""
        if [[ -n "$action" ]]; then
            branch_tooltip="${action} on ${branch}"
        else
            branch_tooltip="Current branch: ${branch}"
        fi

        # Build the status tooltip
        local status_tooltip=""
        if [[ -z "$git_status" ]]; then
            status_tooltip="Working directory is clean"
        else
            local staged=0
            local unstaged=0
            
            local untracked=0
            local conflicts=0
            
            # Count staged, unstaged, untracked, and conflict changes more accurately
            while IFS= read -r line; do
                if [[ ${line:0:2} == "??" ]]; then
                    ((untracked++))
                elif [[ ${line:0:2} == "UU" || ${line:0:2} == "AA" || ${line:0:2} == "DD" ]]; then
                    ((conflicts++))
                else
                    if [[ ${line:0:1} =~ [MADRC] ]]; then
                        ((staged++))
                    fi
                    if [[ ${line:1:1} =~ [MADRC] ]]; then
                        ((unstaged++))
                    fi
                fi
            done < <(echo "$git_status")
            
            # Build tooltip message with proper spacing
            local messages=()
            
            # Add staged files message
            if [[ "$staged" != "0" ]]; then
                if [[ "$staged" == "1" ]]; then
                    messages+=("There is 1 staged file ready to commit")
                else
                    messages+=("There are ${staged} staged files ready to commit")
                fi
            fi
            
            # Add unstaged changes message
            if [[ "$unstaged" != "0" ]]; then
                if [[ "$unstaged" == "1" ]]; then
                    messages+=("There is 1 unstaged change")
                else
                    messages+=("There are ${unstaged} unstaged changes")
                fi
            fi
            
            # Add untracked files message
            if [[ "$untracked" != "0" ]]; then
                if [[ "$untracked" == "1" ]]; then
                    messages+=("There is 1 untracked file")
                else
                    messages+=("There are ${untracked} untracked files")
                fi
            fi
            
            # Add conflicts message
            if [[ "$conflicts" != "0" ]]; then
                if [[ "$conflicts" == "1" ]]; then
                    messages+=("There is 1 unresolved conflict")
                else
                    messages+=("There are ${conflicts} unresolved conflicts")
                fi
            fi
            
            # Join messages with newlines
            status_tooltip=$(IFS=$'\n'; echo "${messages[*]}")
        fi
        
        # Build the visible prompt parts with colors
        # Branch part with its own tooltip
        local branch_part=""
        if [[ -n "$action" ]]; then
            branch_part="%F{red} ${action}%f %F{magenta} ${branch}%f"
        else
            branch_part="%F{magenta} ${branch} %f"
        fi
        
        # Ahead/Behind indicators as separate parts
        # NOTE: Keeping these separate from tooltip system until we find a better solution
        # for displaying multiline tooltips. The ⇡/⇣ indicators serve as a reminder to
        # keep looking for improvements in how we show this information.
        local position_part=""
        [[ -n "$ahead" && "$ahead" != "0" ]] && position_part+=" %F{green}⇡${ahead}%f"
        [[ -n "$behind" && "$behind" != "0" ]] && position_part+=" %F{red}⇣${behind}%f"
        
        # Start with branch part and add position indicators
        local output="$(add_tooltip_trigger "${branch_part}" "${branch_tooltip}")${position_part}"
        
        if [[ -z "$git_status" ]]; then
            # Clean state
            output+=" $(add_tooltip_trigger "%F{green} ✓%f" "${status_tooltip}")"
        else
            # Add staged changes indicator with its own tooltip
            if [[ "$staged" != "0" ]]; then
                local staged_tooltip
                if [[ "$staged" == "1" ]]; then
                    staged_tooltip="There is 1 staged file ready to commit"
                else
                    staged_tooltip="There are ${staged} staged files ready to commit"
                fi
                output+=" $(add_tooltip_trigger "%F{yellow}●${staged}%f" "${staged_tooltip}")"
            fi
            
            # Add unstaged changes indicator with its own tooltip
            if [[ "$unstaged" != "0" ]]; then
                local unstaged_tooltip
                if [[ "$unstaged" == "1" ]]; then
                    unstaged_tooltip="There is 1 unstaged change"
                else
                    unstaged_tooltip="There are ${unstaged} unstaged changes"
                fi
                output+=" $(add_tooltip_trigger "%F{red}●${unstaged}%f" "${unstaged_tooltip}")"
            fi
            
            # Add untracked files indicator with its own tooltip
            if [[ "$untracked" != "0" ]]; then
                local untracked_tooltip
                if [[ "$untracked" == "1" ]]; then
                    untracked_tooltip="There is 1 untracked file"
                else
                    untracked_tooltip="There are ${untracked} untracked files"
                fi
                output+=" $(add_tooltip_trigger "%F{blue}○${untracked}%f" "${untracked_tooltip}")"
            fi
            
            # Add conflicts indicator with its own tooltip
            if [[ "$conflicts" != "0" ]]; then
                local conflicts_tooltip
                if [[ "$conflicts" == "1" ]]; then
                    conflicts_tooltip="There is 1 unresolved conflict"
                else
                    conflicts_tooltip="There are ${conflicts} unresolved conflicts"
                fi
                output+=" $(add_tooltip_trigger "%F{red}✖${conflicts}%f" "${conflicts_tooltip}")"
            fi
            
            # Add stash indicator with its own tooltip
            if [[ "$stash_count" != "0" ]]; then
                local stash_tooltip
                if [[ "$stash_count" == "1" ]]; then
                    stash_tooltip="There is 1 stashed change"
                else
                    stash_tooltip="There are ${stash_count} stashed changes"
                fi
                output+=" $(add_tooltip_trigger "%F{cyan}⚑${stash_count}%f" "${stash_tooltip}")"
            fi
        fi
        
        # Output the complete prompt segment
        echo -n "${output}"
    fi
}
