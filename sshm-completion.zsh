#compdef sshm
# Zsh completion for sshm - SSH File System Mount Manager
#
# Install by placing this file as `_sshm` in a directory on your $fpath
# (e.g. /usr/share/zsh/site-functions/_sshm) and running `compinit`.

# Complete the names of servers saved in the sshm config
_sshm_servers() {
    local config_file="${HOME}/.config/sshm/sshm.json"
    local -a servers
    [[ -f "$config_file" ]] && command -v jq &>/dev/null || return
    servers=(${(f)"$(jq -r '.servers | keys[]' "$config_file" 2>/dev/null)"})
    (( ${#servers} )) && _describe -t servers 'configured server' servers
}

_sshm() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    local -a commands
    commands=(
        'mount:Mount a remote server'
        'umount:Unmount a mounted server'
        'list:List all active SSHFS mounts'
        'add:Add or update a server configuration'
        'edit:Edit an existing server configuration'
        'remove:Remove a server configuration'
        'status:Show configuration and mount status'
        'config:Show current configuration file'
    )

    _arguments -C \
        '(- *)'{-h,--help}'[Show help message]' \
        '(- *)--version[Show version information]' \
        '(- *)--init[Initialize SSHM configuration]' \
        '(- *)'{-c,--clear}'[Clear SSHM mount history]' \
        '(-i --ignore)'{-i,--ignore}'[Ignore known hosts checking]' \
        '(-p --persistent)'{-p,--persistent}'[Make mount persistent across reboots]' \
        '(-d --debug)'{-d,--debug}'[Enable debug output]' \
        '(-v --verbose)'{-v,--verbose}'[Show verbose output (implies debug)]' \
        '1: :->command' \
        '*:: :->args' \
        && return 0

    case $state in
        command)
            _describe -t commands 'sshm command' commands
            _sshm_servers
            ;;
        args)
            case $words[1] in
                mount|umount|edit|remove|add)
                    _sshm_servers
                    ;;
            esac
            ;;
    esac
}

# Support both autoloading (placed on $fpath) and direct sourcing
if [ "$funcstack[1]" = "_sshm" ]; then
    _sshm "$@"
else
    compdef _sshm sshm
fi
