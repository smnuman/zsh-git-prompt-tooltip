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
    echo "%{\e]8;;${tooltip}\a%}${content}%{\e]8;;\a%}"
}

# Git prompt function with tooltip
__git_prompt() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
        local git_status=$(git status --porcelain 2>/dev/null)
        local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
        local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
        
        # Build the branch tooltip
        local branch_tooltip="Current branch: ${branch}"
        [[ -n "$ahead" && "$ahead" != "0" ]] && branch_tooltip="${branch_tooltip}\nAhead by ${ahead} commits"
        [[ -n "$behind" && "$behind" != "0" ]] && branch_tooltip="${branch_tooltip}\nBehind by ${behind} commits"

        # Build the status tooltip
        local status_tooltip=""
        if [[ -z "$git_status" ]]; then
            status_tooltip="Working directory is clean"
        else
            local staged=$(echo "$git_status" | grep -E '^[MADRC]' | wc -l | tr -d ' ')
            local unstaged=$(echo "$git_status" | grep -E '^.[MADRC]' | wc -l | tr -d ' ')
            
            # Handle staged files message
            if [[ "$staged" != "0" ]]; then
                if [[ "$staged" == "1" ]]; then
                    status_tooltip="There is 1 staged file ready to commit"
                else
                    status_tooltip="There are ${staged} staged files ready to commit"
                fi
            fi
            
            # Handle unstaged changes message
            if [[ "$unstaged" != "0" ]]; then
                if [[ "$unstaged" == "1" ]]; then
                    status_tooltip="${status_tooltip:+$status_tooltip\n}There is 1 unstaged change"
                else
                    status_tooltip="${status_tooltip:+$status_tooltip\n}There are ${unstaged} unstaged changes"
                fi
            fi
        fi
        
        # Build the visible prompt parts with colors
        local branch_part="%F{magenta} ${branch} %f"
        [[ -n "$ahead" && "$ahead" != "0" ]] && branch_part+=" %F{green}⇡${ahead}%f"
        [[ -n "$behind" && "$behind" != "0" ]] && branch_part+=" %F{red}⇣${behind}%f"
        
        local status_part=""
        if [[ -z "$git_status" ]]; then
            status_part=" %F{green}✓%f"
        else
            [[ "$staged" != "0" ]] && status_part+=" %F{yellow}●${staged}%f"
            [[ "$unstaged" != "0" ]] && status_part+=" %F{red}●${unstaged}%f"
        fi

        # Output with separate tooltips for branch and status
        echo -n "$(add_tooltip_trigger "${branch_part}" "${branch_tooltip}")"\
"$([ -n "${status_part}" ] && add_tooltip_trigger "${status_part}" "${status_tooltip}")"
    fi
}
