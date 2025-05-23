# Git Prompt with Tooltips

A ZSH plugin that enhances your prompt with git information and interactive tooltips.

## Features

- Shows git branch name with tooltip
- Indicates ahead/behind status with arrows (⇡/⇣)
- Shows staged/unstaged changes with dots (●)
- Interactive tooltips on hover
- Singular/plural message handling
- Color-coded status indicators

## Installation

1. Clone this repository in your ZSH plugins directory:
```bash
git clone https://github.com/yourusername/zsh-git-prompt ~/.zsh/plugins/git-prompt
```

2. Source the plugin in your `.zshrc`:
```bash
source ~/.zsh/plugins/git-prompt/git-prompt.plugin.zsh
```

## Usage

The plugin automatically integrates with your prompt. Just make sure to include `$(__git_prompt)` in your PROMPT variable.

Example:
```bash
PROMPT='${time_info}${current_dir}$(__git_prompt)${ret_status} '
```

## License

MIT
