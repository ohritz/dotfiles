autoload -Uz add-zsh-hook
# Use XDG_STATE_HOME for logs (state data that persists across sessions)
CMDLOGFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/command.log"
# this is overly complicated so it only chmod's the file if it is creating
# the file for the first time, while still verifying we can write to the file
# via touch, and unsetting the variable if we can not write to it
if [ -n "$CMDLOGFILE" ]; then
    # check if file exists
    if [ -f "$CMDLOGFILE" ]; then
        if touch $CMDLOGFILE 2>/dev/null; then
            : # filesystem is writable
        else
            unset CMDLOGFILE
        fi
    else
        # try to create file and set mode
        if touch $CMDLOGFILE 2>/dev/null; then
            # filesystem is writable
            chmod 600 $CMDLOGFILE
        else
            unset CMDLOGFILE
        fi
    fi
fi
if [ -n "$CMDLOGFILE" ]; then
    # if still set, activate logging
    zmodload -i zsh/datetime
    function log_command {
        print -r "$(strftime '%Y-%m-%d %H:%M:%S %Z' $EPOCHSECONDS) $LOGNAME: $3" >>$CMDLOGFILE
    }
    add-zsh-hook preexec log_command
fi
