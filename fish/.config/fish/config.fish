if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Starship initialization
starship init fish | source

# EZA Aliases
alias ls 'eza --color=always --group-directories-first --icons'
alias ll 'eza -l --color=always --group-directories-first --icons --git --time-style=long-iso'
alias la 'eza -a --color=always --group-directories-first --icons'
alias l 'eza -lah --color=always --group-directories-first --icons --git --time-style=long-iso'
alias lt 'eza -aT --color=always --group-directories-first --icons'
alias l. 'eza -a | grep -E "^\."'  # Show only dotfiles

# System Aliases
alias update-grub 'sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias backup 'sudo timeshift --create --comments "archbtw-backup-"(date +%Y%m%d)'
alias shutdown 'systemctl poweroff'
alias reload 'source ~/.config/fish/config.fish'

# Basic Aliases
alias c 'clear'
alias h 'history'
alias q 'exit'
 
# Fish-specific settings
set -g fish_greeting ""

# Fish-specific aliases
alias fishconfig '$EDITOR ~/.config/fish/config.fish'

# Fish-specific functions
function mkcd
    mkdir -p $argv[1]; and cd $argv[1]
end

function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

string match -q "$TERM_PROGRAM" "kiro" and . (kiro --locate-shell-integration-path fish)
