#!/bin/bash

_sshm_completion() {
    local cur prev words cword
    _init_completion || return

    local commands="mount umount list add edit remove status config"
    local options="-i --ignore -p --persistent -d --debug -v --verbose -c --clear --init --version -h --help -?"
    local config_file="$HOME/.config/sshm/sshm.json"

    # Handle completion after specific commands
    case $prev in
        mount|umount|edit|remove)
            if [[ -f "$config_file" ]] && command -v jq &> /dev/null; then
                local servers
                servers=$(jq -r '.servers | keys[]' "$config_file" 2>/dev/null)
                COMPREPLY=($(compgen -W "$servers" -- "$cur"))
            fi
            return 0
            ;;
        add)
            # For add command, suggest configured servers (for editing) or let user type new ones
            if [[ -f "$config_file" ]] && command -v jq &> /dev/null; then
                local servers
                servers=$(jq -r '.servers | keys[]' "$config_file" 2>/dev/null)
                COMPREPLY=($(compgen -W "$servers" -- "$cur"))
            fi
            return 0
            ;;
    esac

    # Handle options
    if [[ $cur == -* ]]; then
        COMPREPLY=($(compgen -W "$options" -- "$cur"))
        return 0
    fi

    # Check if we're in the first position (after sshm)
    local word_count=0
    local has_command=false
    
    for ((i=1; i < cword; i++)); do
        case ${words[i]} in
            # Skip options
            -*)
                continue
                ;;
            # These are commands
            mount|umount|list|add|edit|remove|status|config)
                has_command=true
                word_count=$((word_count + 1))
                ;;
            # Everything else counts as a word
            *)
                word_count=$((word_count + 1))
                ;;
        esac
    done

    # If no command has been specified yet and we're at the first word
    if [[ $word_count -eq 0 && "$has_command" == false ]]; then
        local all_completions="$commands"
        
        # Add configured servers for direct mounting
        if [[ -f "$config_file" ]] && command -v jq &> /dev/null; then
            local servers
            servers=$(jq -r '.servers | keys[]' "$config_file" 2>/dev/null)
            all_completions="$all_completions $servers"
        fi
        
        COMPREPLY=($(compgen -W "$all_completions" -- "$cur"))
    else
        # Context-specific completions based on what's already been entered
        COMPREPLY=()
    fi
}

complete -F _sshm_completion sshm