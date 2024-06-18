# Decker prompt
# by Sohan Fernando
# Modified from Pure
# by Sindre Sorhus
# https://github.com/sindresorhus/pure
# MIT License

# For my own and others sanity
# git:
# %b => current branch
# %a => current action (rebase/merge)
# prompt:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)
# terminal codes:
# \e7   => save cursor position
# \e[2A => move cursor 2 lines up
# \e[1G => go to position 1 in terminal
# \e8   => restore cursor position
# \e[K  => clears everything after the cursor on the current line
# \e[2K => clear everything on the current line

ZSH_THEME_KUBECTX_PROMT_PREFIX="["
ZSH_THEME_KUBECTX_PROMT_SUFFIX="]"

# Turns seconds into human readable time.
# 165392 => 1d 21h 56m 32s
# https://github.com/sindresorhus/pretty-time-zsh
prompt_decker_human_time_to_var() {
	local human total_seconds=$1 var=$2
	local days=$(( total_seconds / 60 / 60 / 24 ))
	local hours=$(( total_seconds / 60 / 60 % 24 ))
	local minutes=$(( total_seconds / 60 % 60 ))
	local seconds=$(( total_seconds % 60 ))
	(( days > 0 )) && human+="${days}d "
	(( hours > 0 )) && human+="${hours}h "
	(( minutes > 0 )) && human+="${minutes}m "
	human+="${seconds}s"

	# Store human readable time in a variable as specified by the caller
	typeset -g "${var}"="${human}"
}

# Stores (into prompt_decker_cmd_exec_time) the execution
# time of the last command if set threshold was exceeded.
prompt_decker_check_cmd_exec_time() {
	integer elapsed
	(( elapsed = EPOCHSECONDS - ${prompt_decker_cmd_timestamp:-$EPOCHSECONDS} ))
	typeset -g prompt_decker_cmd_exec_time=
	(( elapsed > ${PURE_CMD_MAX_EXEC_TIME:-5} )) && {
		prompt_decker_human_time_to_var $elapsed "prompt_decker_cmd_exec_time"
	}
}

prompt_decker_kubectx_prompt_info() {
    if zstyle -t ':ohritz:decker' disable_kubectxprompt; then return; fi
    local current_context=$(kubectx_prompt_info)

    if [ -n "$current_context" ]; then
        echo "${ZSH_THEME_KUBECTX_PROMT_PREFIX}${current_context}${ZSH_THEME_KUBECTX_PROMT_SUFFIX}"
    fi
}

prompt_decker_preexec() {
	if [[ -n $prompt_decker_git_fetch_pattern ]]; then
		# Detect when Git is performing pull/fetch, including Git aliases.
		local -H MATCH MBEGIN MEND match mbegin mend
		if [[ $2 =~ (git|hub)\ (.*\ )?($prompt_decker_git_fetch_pattern)(\ .*)?$ ]]; then
			# We must flush the async jobs to cancel our git fetch in order
			# to avoid conflicts with the user issued pull / fetch.
			async_flush_jobs 'prompt_decker'
		fi
	fi

	typeset -g prompt_decker_cmd_timestamp=$EPOCHSECONDS

	# Disallow Python virtualenv from updating the prompt. Set it to 12 if
	# untouched by the user to indicate that Pure modified it. Here we use
	# the magic number 12, same as in `psvar`.
	export VIRTUAL_ENV_DISABLE_PROMPT=${VIRTUAL_ENV_DISABLE_PROMPT:-12}
}

# Change the colors if their value are different from the current ones.
prompt_decker_set_colors() {
	local color_temp key value
	for key value in ${(kv)prompt_decker_colors}; do
		zstyle -t ":prompt:decker:$key" color "$value"
		case $? in
			1) # The current style is different from the one from zstyle.
				zstyle -s ":prompt:decker:$key" color color_temp
				prompt_decker_colors[$key]=$color_temp ;;
			2) # No style is defined.
				prompt_decker_colors[$key]=$prompt_decker_colors_default[$key] ;;
		esac
	done
}

prompt_decker_preprompt_render() {
	setopt localoptions noshwordsplit

	unset prompt_decker_async_render_requested

	# Initialize the preprompt array.
	local -a preprompt_middle_parts
	local -a preprompt_top_parts
	local -ah ps1
	local -ah preprompt_right_parts
	typeset -g prompt_decker_last_exit_code

	local sep_color=$prompt_decker_colors[separator]
	# Set color for Git branch/dirty status and change color if dirty checking has been delayed.
	local git_color=$prompt_decker_colors[git:branch]
	local git_dirty_color=$prompt_decker_colors[git:dirty]
	[[ -n ${prompt_decker_git_last_dirty_check_timestamp+x} ]] && git_color=$prompt_decker_colors[git:branch:cached]

	## Build top part of preprompt
	# Git branch and dirty status info.
	typeset -gA prompt_decker_vcs_info
	if [[ -n $prompt_decker_vcs_info[branch] ]]; then
		preprompt_top_parts+=("%F{$sep_color}┌%f")
		preprompt_top_parts+=("%F{$sep_color}[$(print '\uE0A0')%f")
		preprompt_top_parts+=("%F{$git_color}"'${prompt_decker_vcs_info[branch]}'"%F{$git_dirty_color}"'${prompt_decker_git_dirty}%f')
		preprompt_top_parts+=("%F{$sep_color}]%f")
	fi

	# Git action (for example, merge).
	if [[ -n $prompt_decker_vcs_info[action] ]]; then
		preprompt_top_parts+=("%F{$prompt_decker_colors[git:action]}"'$prompt_decker_vcs_info[action]%f')
	fi
	# Git pull/push arrows.
	if [[ -n $prompt_decker_git_arrows ]]; then
		preprompt_top_parts+=('%F{$prompt_decker_colors[git:arrow]}${prompt_decker_git_arrows}%f')
	fi
	# Git stash symbol (if opted in).
	if [[ -n $prompt_decker_git_stash ]]; then
		preprompt_top_parts+=('%F{$prompt_decker_colors[git:stash]}${PURE_GIT_STASH_SYMBOL:-≡}%f')
	fi


	if [[ -n $prompt_decker_vcs_info[branch] ]]; then
		# Add cross divider to middle part
		preprompt_middle_parts+=("%F{$sep_color}├[%f")

		# Add top part to ps1
		ps1=(
			${(j..)preprompt_top_parts}
			$prompt_newline
		)
	else
		preprompt_middle_parts+=("%F{$sep_color}┌[%f")
	fi

	## Build middle part of preprompt

	# clock and time
	preprompt_middle_parts+=("$(emoji-clock)")
	preprompt_middle_parts+=("%F{${prompt_decker_colors[path]}} %*%f")
	preprompt_middle_parts+=("%F{$sep_color}]-[%f")

	# Username and machine, if applicable.
	if [[ -n $prompt_decker_state[username] ]]; then
		preprompt_middle_parts+=($prompt_decker_state[username])
		preprompt_middle_parts+=("%F{$sep_color}]-[%f")
	fi


	# Set the path.
	preprompt_middle_parts+=('%F{${prompt_decker_colors[path]}}%~%f')
	preprompt_middle_parts+=("%F{$sep_color}]%f")

	# Suspended jobs in background.
	if ((${(M)#jobstates:#suspended:*} != 0)); then
		preprompt_middle_parts+=('%F{$prompt_decker_colors[suspended_jobs]}✦%F{$sep_color}%f')
	fi

	# Execution time.
	[[ -n $prompt_decker_cmd_exec_time ]] && preprompt_middle_parts+=('%F{$prompt_decker_colors[execution_time]}${prompt_decker_cmd_exec_time}%f')


	if [[ $prompt_decker_last_exit_code -ne 0 ]]; then
		preprompt_middle_parts+=('%F{${prompt_decker_colors[prompt:error]}}!%f')
	fi

	ps1+=(
		${(j..)preprompt_middle_parts}
		$prompt_newline
	)

	RPROMPT="$(prompt_decker_kubectx_prompt_info)"

	local cleaned_ps1=$PROMPT
	local -H MATCH MBEGIN MEND
	if [[ $PROMPT = *$prompt_newline* ]]; then
		# Remove everything from the prompt until the newline. This
		# removes the preprompt and only the original PROMPT remains.
		cleaned_ps1=${PROMPT##*${prompt_newline}}
	fi
	unset MATCH MBEGIN MEND

	# Construct the new prompt with a clean preprompt.
	ps1+=$cleaned_ps1

	PROMPT="${(j..)ps1}"

	# Expand the prompt for future comparision.
	local expanded_prompt
	expanded_prompt="${(S%%)PROMPT}"

	if [[ $1 == precmd ]]; then
		# Initial newline, for spaciousness.
		print
	elif [[ $prompt_decker_last_prompt != $expanded_prompt ]]; then
		# Redraw the prompt.
		prompt_decker_reset_prompt
	fi

	typeset -g prompt_decker_last_prompt=$expanded_prompt
}


prompt_check_last_exit_code() {
	local LAST_EXIT_CODE=$?
	typeset -g prompt_decker_last_exit_code=$LAST_EXIT_CODE
}

prompt_decker_precmd() {
	setopt localoptions noshwordsplit

	# Check execution time and store it in a variable.
	prompt_decker_check_cmd_exec_time
	unset prompt_decker_cmd_timestamp

	# Modify the colors if some have changed..
	prompt_decker_set_colors

	# Perform async Git dirty check and fetch.
	prompt_decker_async_tasks

	# Check if we should display the virtual env. We use a sufficiently high
	# index of psvar (12) here to avoid collisions with user defined entries.
	psvar[12]=
	# Check if a Conda environment is active and display its name.
	if [[ -n $CONDA_DEFAULT_ENV ]]; then
		psvar[12]="${CONDA_DEFAULT_ENV//[$'\t\r\n']}"
	fi
	# When VIRTUAL_ENV_DISABLE_PROMPT is empty, it was unset by the user and
	# Pure should take back control.
	if [[ -n $VIRTUAL_ENV ]] && [[ -z $VIRTUAL_ENV_DISABLE_PROMPT || $VIRTUAL_ENV_DISABLE_PROMPT = 12 ]]; then
		psvar[12]="${VIRTUAL_ENV:t}"
		export VIRTUAL_ENV_DISABLE_PROMPT=12
	fi

	# Nix package manager integration. If used from within 'nix shell' - shell name is shown like so:
	# ~/Projects/flake-utils-plus master
	# flake-utils-plus ❯
	if zstyle -T ":prompt:decker:environment:nix-shell" show; then
		if [[ -n $IN_NIX_SHELL ]]; then
			psvar[12]="${name:-nix-shell}"
		fi
	fi

	# Make sure VIM prompt is reset.
	prompt_decker_reset_prompt_symbol

	# Print the preprompt.
	prompt_decker_preprompt_render "precmd"
}

prompt_decker_async_git_aliases() {
	setopt localoptions noshwordsplit
	local -a gitalias pullalias

	# List all aliases and split on newline.
	gitalias=(${(@f)"$(command git config --get-regexp "^alias\.")"})
	for line in $gitalias; do
		parts=(${(@)=line})           # Split line on spaces.
		aliasname=${parts[1]#alias.}  # Grab the name (alias.[name]).
		shift parts                   # Remove `aliasname`

		# Check alias for pull or fetch. Must be exact match.
		if [[ $parts =~ ^(.*\ )?(pull|fetch)(\ .*)?$ ]]; then
			pullalias+=($aliasname)
		fi
	done

	print -- ${(j:|:)pullalias}  # Join on pipe, for use in regex.
}

prompt_decker_async_vcs_info() {
	setopt localoptions noshwordsplit

	# Configure `vcs_info` inside an async task. This frees up `vcs_info`
	# to be used or configured as the user pleases.
	zstyle ':vcs_info:*' enable git
	zstyle ':vcs_info:*' use-simple true
	# Only export four message variables from `vcs_info`.
	zstyle ':vcs_info:*' max-exports 3
	# Export branch (%b), Git toplevel (%R), action (rebase/cherry-pick) (%a)
	zstyle ':vcs_info:git*' formats '%b' '%R' '%a'
	zstyle ':vcs_info:git*' actionformats '%b' '%R' '%a'

	vcs_info

	local -A info
	info[pwd]=$PWD
	info[branch]=${vcs_info_msg_0_//\%/%%}
	info[top]=$vcs_info_msg_1_
	info[action]=$vcs_info_msg_2_

	print -r - ${(@kvq)info}
}

# Fastest possible way to check if a Git repo is dirty.
prompt_decker_async_git_dirty() {
	setopt localoptions noshwordsplit
	local untracked_dirty=$1
	local untracked_git_mode=$(command git config --get status.showUntrackedFiles)
	if [[ "$untracked_git_mode" != 'no' ]]; then
		untracked_git_mode='normal'
	fi

	# Prevent e.g. `git status` from refreshing the index as a side effect.
	export GIT_OPTIONAL_LOCKS=0

	if [[ $untracked_dirty = 0 ]]; then
		command git diff --no-ext-diff --quiet --exit-code
	else
		test -z "$(command git status --porcelain -u${untracked_git_mode})"
	fi

	return $?
}

prompt_decker_async_git_fetch() {
	setopt localoptions noshwordsplit

	local only_upstream=${1:-0}

	# Sets `GIT_TERMINAL_PROMPT=0` to disable authentication prompt for Git fetch (Git 2.3+).
	export GIT_TERMINAL_PROMPT=0
	# Set SSH `BachMode` to disable all interactive SSH password prompting.
	export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-"ssh"} -o BatchMode=yes"

	# If gpg-agent is set to handle SSH keys for `git fetch`, make
	# sure it doesn't corrupt the parent TTY.
	# Setting an empty GPG_TTY forces pinentry-curses to close immediately rather
	# than stall indefinitely waiting for user input.
	export GPG_TTY=

	local -a remote
	if ((only_upstream)); then
		local ref
		ref=$(command git symbolic-ref -q HEAD)
		# Set remote to only fetch information for the current branch.
		remote=($(command git for-each-ref --format='%(upstream:remotename) %(refname)' $ref))
		if [[ -z $remote[1] ]]; then
			# No remote specified for this branch, skip fetch.
			return 97
		fi
	fi

	# Default return code, which indicates Git fetch failure.
	local fail_code=99

	# Guard against all forms of password prompts. By setting the shell into
	# MONITOR mode we can notice when a child process prompts for user input
	# because it will be suspended. Since we are inside an async worker, we
	# have no way of transmitting the password and the only option is to
	# kill it. If we don't do it this way, the process will corrupt with the
	# async worker.
	setopt localtraps monitor

	# Make sure local HUP trap is unset to allow for signal propagation when
	# the async worker is flushed.
	trap - HUP

	trap '
		# Unset trap to prevent infinite loop
		trap - CHLD
		if [[ $jobstates = suspended* ]]; then
			# Set fail code to password prompt and kill the fetch.
			fail_code=98
			kill %%
		fi
	' CHLD

	# Do git fetch and avoid fetching tags or
	# submodules to speed up the process.
	command git -c gc.auto=0 fetch \
		--quiet \
		--no-tags \
		--recurse-submodules=no \
		$remote &>/dev/null &
	wait $! || return $fail_code

	unsetopt monitor

	# Check arrow status after a successful `git fetch`.
	prompt_decker_async_git_arrows
}

prompt_decker_async_git_arrows() {
	setopt localoptions noshwordsplit
	command git rev-list --left-right --count HEAD...@'{u}'
}

prompt_decker_async_git_stash() {
	git rev-list --walk-reflogs --count refs/stash
}

# Try to lower the priority of the worker so that disk heavy operations
# like `git status` has less impact on the system responsivity.
prompt_decker_async_renice() {
	setopt localoptions noshwordsplit

	if command -v renice >/dev/null; then
		command renice +15 -p $$
	fi

	if command -v ionice >/dev/null; then
		command ionice -c 3 -p $$
	fi
}

prompt_decker_async_init() {
	typeset -g prompt_decker_async_inited
	if ((${prompt_decker_async_inited:-0})); then
		return
	fi
	prompt_decker_async_inited=1
	async_start_worker "prompt_decker" -u -n
	async_register_callback "prompt_decker" prompt_decker_async_callback
	async_worker_eval "prompt_decker" prompt_decker_async_renice
}

prompt_decker_async_tasks() {
	setopt localoptions noshwordsplit

	# Initialize the async worker.
	prompt_decker_async_init

	# Update the current working directory of the async worker.
	async_worker_eval "prompt_decker" builtin cd -q $PWD

	typeset -gA prompt_decker_vcs_info

	local -H MATCH MBEGIN MEND
	if [[ $PWD != ${prompt_decker_vcs_info[pwd]}* ]]; then
		# Stop any running async jobs.
		async_flush_jobs "prompt_decker"

		# Reset Git preprompt variables, switching working tree.
		unset prompt_decker_git_dirty
		unset prompt_decker_git_last_dirty_check_timestamp
		unset prompt_decker_git_arrows
		unset prompt_decker_git_stash
		unset prompt_decker_git_fetch_pattern
		prompt_decker_vcs_info[branch]=
		prompt_decker_vcs_info[top]=
	fi
	unset MATCH MBEGIN MEND

	async_job "prompt_decker" prompt_decker_async_vcs_info

	[[ -n $prompt_decker_vcs_info[top] ]] || return

	prompt_decker_async_git_refresh
}

prompt_decker_async_git_refresh() {
	setopt localoptions noshwordsplit

	if [[ -z $prompt_decker_git_fetch_pattern ]]; then
		# We set the pattern here to avoid redoing the pattern check until the
		# working tree has changed. Pull and fetch are always valid patterns.
		typeset -g prompt_decker_git_fetch_pattern="pull|fetch"
		async_job "prompt_decker" prompt_decker_async_git_aliases
	fi

	async_job "prompt_decker" prompt_decker_async_git_arrows

	# Do not perform `git fetch` if it is disabled or in home folder.
	if (( ${DECKER_GIT_PULL:-1} )) && [[ $prompt_decker_vcs_info[top] != $HOME ]]; then
		zstyle -t :prompt:decker:git:fetch only_upstream
		local only_upstream=$((? == 0))
		async_job "prompt_decker" prompt_decker_async_git_fetch $only_upstream
	fi

	# If dirty checking is sufficiently fast,
	# tell the worker to check it again, or wait for timeout.
	integer time_since_last_dirty_check=$(( EPOCHSECONDS - ${prompt_decker_git_last_dirty_check_timestamp:-0} ))
	if (( time_since_last_dirty_check > ${PURE_GIT_DELAY_DIRTY_CHECK:-1800} )); then
		unset prompt_decker_git_last_dirty_check_timestamp
		# Check check if there is anything to pull.
		async_job "prompt_decker" prompt_decker_async_git_dirty ${PURE_GIT_UNTRACKED_DIRTY:-1}
	fi

	# If stash is enabled, tell async worker to count stashes
	if zstyle -t ":prompt:decker:git:stash" show; then
		async_job "prompt_decker" prompt_decker_async_git_stash
	else
		unset prompt_decker_git_stash
	fi
}

prompt_decker_check_git_arrows() {
	setopt localoptions noshwordsplit
	local arrows left=${1:-0} right=${2:-0}

	(( right > 0 )) && arrows+=${PURE_GIT_DOWN_ARROW:-⇣}
	(( left > 0 )) && arrows+=${PURE_GIT_UP_ARROW:-⇡}

	[[ -n $arrows ]] || return
	typeset -g REPLY=$arrows
}

prompt_decker_async_callback() {
	setopt localoptions noshwordsplit
	local job=$1 code=$2 output=$3 exec_time=$4 next_pending=$6
	local do_render=0

	case $job in
		\[async])
			# Handle all the errors that could indicate a crashed
			# async worker. See zsh-async documentation for the
			# definition of the exit codes.
			if (( code == 2 )) || (( code == 3 )) || (( code == 130 )); then
				# Our worker died unexpectedly, try to recover immediately.
				# TODO(mafredri): Do we need to handle next_pending
				#                 and defer the restart?
				typeset -g prompt_decker_async_inited=0
				async_stop_worker prompt_decker
				prompt_decker_async_init   # Reinit the worker.
				prompt_decker_async_tasks  # Restart all tasks.

				# Reset render state due to restart.
				unset prompt_decker_async_render_requested
			fi
			;;
		\[async/eval])
			if (( code )); then
				# Looks like async_worker_eval failed,
				# rerun async tasks just in case.
				prompt_decker_async_tasks
			fi
			;;
		prompt_decker_async_vcs_info)
			local -A info
			typeset -gA prompt_decker_vcs_info

			# Parse output (z) and unquote as array (Q@).
			info=("${(Q@)${(z)output}}")
			local -H MATCH MBEGIN MEND
			if [[ $info[pwd] != $PWD ]]; then
				# The path has changed since the check started, abort.
				return
			fi
			# Check if Git top-level has changed.
			if [[ $info[top] = $prompt_decker_vcs_info[top] ]]; then
				# If the stored pwd is part of $PWD, $PWD is shorter and likelier
				# to be top-level, so we update pwd.
				if [[ $prompt_decker_vcs_info[pwd] = ${PWD}* ]]; then
					prompt_decker_vcs_info[pwd]=$PWD
				fi
			else
				# Store $PWD to detect if we (maybe) left the Git path.
				prompt_decker_vcs_info[pwd]=$PWD
			fi
			unset MATCH MBEGIN MEND

			# The update has a Git top-level set, which means we just entered a new
			# Git directory. Run the async refresh tasks.
			[[ -n $info[top] ]] && [[ -z $prompt_decker_vcs_info[top] ]] && prompt_decker_async_git_refresh

			# Always update branch, top-level and stash.
			prompt_decker_vcs_info[branch]=$info[branch]
			prompt_decker_vcs_info[top]=$info[top]
			prompt_decker_vcs_info[action]=$info[action]

			do_render=1
			;;
		prompt_decker_async_git_aliases)
			if [[ -n $output ]]; then
				# Append custom Git aliases to the predefined ones.
				prompt_decker_git_fetch_pattern+="|$output"
			fi
			;;
		prompt_decker_async_git_dirty)
			local prev_dirty=$prompt_decker_git_dirty
			if (( code == 0 )); then
				unset prompt_decker_git_dirty
			else
				typeset -g prompt_decker_git_dirty="*"
			fi

			[[ $prev_dirty != $prompt_decker_git_dirty ]] && do_render=1

			# When `prompt_decker_git_last_dirty_check_timestamp` is set, the Git info is displayed
			# in a different color. To distinguish between a "fresh" and a "cached" result, the
			# preprompt is rendered before setting this variable. Thus, only upon the next
			# rendering of the preprompt will the result appear in a different color.
			(( $exec_time > 5 )) && prompt_decker_git_last_dirty_check_timestamp=$EPOCHSECONDS
			;;
		prompt_decker_async_git_fetch|prompt_decker_async_git_arrows)
			# `prompt_decker_async_git_fetch` executes `prompt_decker_async_git_arrows`
			# after a successful fetch.
			case $code in
				0)
					local REPLY
					prompt_decker_check_git_arrows ${(ps:\t:)output}
					if [[ $prompt_decker_git_arrows != $REPLY ]]; then
						typeset -g prompt_decker_git_arrows=$REPLY
						do_render=1
					fi
					;;
				97)
					# No remote available, make sure to clear git arrows if set.
					if [[ -n $prompt_decker_git_arrows ]]; then
						typeset -g prompt_decker_git_arrows=
						do_render=1
					fi
					;;
				99|98)
					# Git fetch failed.
					;;
				*)
					# Non-zero exit status from `prompt_decker_async_git_arrows`,
					# indicating that there is no upstream configured.
					if [[ -n $prompt_decker_git_arrows ]]; then
						unset prompt_decker_git_arrows
						do_render=1
					fi
					;;
			esac
			;;
		prompt_decker_async_git_stash)
			local prev_stash=$prompt_decker_git_stash
			typeset -g prompt_decker_git_stash=$output
			[[ $prev_stash != $prompt_decker_git_stash ]] && do_render=1
			;;
	esac

	if (( next_pending )); then
		(( do_render )) && typeset -g prompt_decker_async_render_requested=1
		return
	fi

	[[ ${prompt_decker_async_render_requested:-$do_render} = 1 ]] && prompt_decker_preprompt_render
	unset prompt_decker_async_render_requested
}

prompt_decker_reset_prompt() {
	if [[ $CONTEXT == cont ]]; then
		# When the context is "cont", PS2 is active and calling
		# reset-prompt will have no effect on PS1, but it will
		# reset the execution context (%_) of PS2 which we don't
		# want. Unfortunately, we can't save the output of "%_"
		# either because it is only ever rendered as part of the
		# prompt, expanding in-place won't work.
		return
	fi

	zle && zle .reset-prompt
}

prompt_build_decker_base_prompt() {
	setopt localoptions noshwordsplit
	typeset -gA prompt_decker_state
	typeset -g prompt_pointer_symbol

	local -a preprompt_base_top_parts
	local -a preprompt_base_bottom_parts

	preprompt_base_top_parts+=("%F{$prompt_decker_colors[separator]}┌[%f")

	preprompt_base_top_parts+=("$(emoji-clock)")
	preprompt_base_top_parts+=("%F{${prompt_decker_colors[path]}} %*%f")
	preprompt_base_top_parts+=("%F{$prompt_decker_colors[separator]}]-[%f")
	preprompt_base_top_parts+=('%F{${prompt_decker_colors[path]}}%~%f')
	preprompt_base_top_parts+=("%F{$prompt_decker_colors[separator]}]%f")

	preprompt_base_bottom_parts+=("%F{$prompt_decker_colors[separator]}└%f")

	[[ -n $prompt_decker_state[username] ]] && preprompt_base_bottom_parts+=($prompt_decker_state[username])

	preprompt_base_bottom_parts+=("${prompt_pointer_symbol}")

	local -ah ps1
	local base_prompt
	ps1=(
		${(j..)preprompt_base_top_parts}
		$prompt_newline
		${(j..)preprompt_base_bottom_parts}
	)
	base_prompt="${(j..)ps1}"

	prompt_decker_state[prompt]=${base_prompt}
}

prompt_decker_reset_prompt_symbol() {
	prompt_build_decker_base_prompt
}

prompt_decker_update_vim_prompt_widget() {
	setopt localoptions noshwordsplit
	prompt_decker_state[prompt]=${${KEYMAP/vicmd/${DECKER_PROMPT_VICMD_SYMBOL:-⮜}}/(main|viins)/${DECKER_PROMPT_SYMBOL:-⮞}}

	prompt_decker_reset_prompt
}

prompt_decker_reset_vim_prompt_widget() {
	setopt localoptions noshwordsplit
	prompt_decker_reset_prompt_symbol

	# We can't perform a prompt reset at this point because it
	# removes the prompt marks inserted by macOS Terminal.
}

prompt_decker_state_setup() {
	setopt localoptions noshwordsplit

	# Check SSH_CONNECTION and the current state.
	local ssh_connection=${SSH_CONNECTION:-$PROMPT_DECKER_SSH_CONNECTION}
	local username hostname
	if [[ -z $ssh_connection ]] && (( $+commands[who] )); then
		# When changing user on a remote system, the $SSH_CONNECTION
		# environment variable can be lost. Attempt detection via `who`.
		local who_out
		who_out=$(who -m 2>/dev/null)
		if (( $? )); then
			# Who am I not supported, fallback to plain who.
			local -a who_in
			who_in=( ${(f)"$(who 2>/dev/null)"} )
			who_out="${(M)who_in:#*[[:space:]]${TTY#/dev/}[[:space:]]*}"
		fi

		local reIPv6='(([0-9a-fA-F]+:)|:){2,}[0-9a-fA-F]+'  # Simplified, only checks partial pattern.
		local reIPv4='([0-9]{1,3}\.){3}[0-9]+'   # Simplified, allows invalid ranges.
		# Here we assume two non-consecutive periods represents a
		# hostname. This matches `foo.bar.baz`, but not `foo.bar`.
		local reHostname='([.][^. ]+){2}'

		# Usually the remote address is surrounded by parenthesis, but
		# not on all systems (e.g. busybox).
		local -H MATCH MBEGIN MEND
		if [[ $who_out =~ "\(?($reIPv4|$reIPv6|$reHostname)\)?\$" ]]; then
			ssh_connection=$MATCH

			# Export variable to allow detection propagation inside
			# shells spawned by this one (e.g. tmux does not always
			# inherit the same tty, which breaks detection).
			export PROMPT_DECKER_SSH_CONNECTION=$ssh_connection
		fi
		unset MATCH MBEGIN MEND
	fi

	hostname='%F{$prompt_decker_colors[host]}@%m%f'
	# Show `username@host` if logged in through SSH.
	[[ -n $ssh_connection ]] && username='%F{$prompt_decker_colors[user]}%n%f'"$hostname"

	# Show `username@host` if inside a container and not in GitHub Codespaces.
	[[ -z "${CODESPACES}" ]] && prompt_decker_is_inside_container && username='%F{$prompt_decker_colors[user]}%n%f'"$hostname"

	# Show `username@host` if root, with username in default color.
	[[ $UID -eq 0 ]] && username='%F{$prompt_decker_colors[user:root]}%n%f'"$hostname"

	typeset -g prompt_pointer_symbol=${DECKER_PROMPT_SYMBOL:-➤}
	typeset -gA prompt_decker_state
	prompt_decker_state[version]="1.0.0"
	prompt_decker_state+=(
		username "$username"
		prompt	 "${prompt_pointer_symbol}"
	)
	prompt_build_decker_base_prompt
}

# Return true if executing inside a Docker, OCI, LXC, or systemd-nspawn container.
prompt_decker_is_inside_container() {
	local -r cgroup_file='/proc/1/cgroup'
	local -r nspawn_file='/run/host/container-manager'
	[[ -r "$cgroup_file" && "$(< $cgroup_file)" = *(lxc|docker)* ]] \
		|| [[ "$container" == "lxc" ]] \
		|| [[ "$container" == "oci" ]] \
		|| [[ -r "$nspawn_file" ]]
}

prompt_decker_system_report() {
	setopt localoptions noshwordsplit

	local shell=$SHELL
	if [[ -z $shell ]]; then
		shell=$commands[zsh]
	fi
	print - "- Zsh: $($shell --version) ($shell)"
	print -n - "- Operating system: "
	case "$(uname -s)" in
		Darwin)	print "$(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))";;
		*)	print "$(uname -s) ($(uname -r) $(uname -v) $(uname -m) $(uname -o))";;
	esac
	print - "- Terminal program: ${TERM_PROGRAM:-unknown} (${TERM_PROGRAM_VERSION:-unknown})"
	print -n - "- Tmux: "
	[[ -n $TMUX ]] && print "yes" || print "no"

	local git_version
	git_version=($(git --version))  # Remove newlines, if hub is present.
	print - "- Git: $git_version"

	print - "- Decker state:"
	for k v in "${(@kv)prompt_decker_state}"; do
		print - "    - $k: \`${(q-)v}\`"
	done
	print - "- zsh-async version: \`${ASYNC_VERSION}\`"
	print - "- PROMPT: \`$(typeset -p PROMPT)\`"
	print - "- Colors: \`$(typeset -p prompt_decker_colors)\`"
	print - "- TERM: \`$(typeset -p TERM)\`"
	print - "- Virtualenv: \`$(typeset -p VIRTUAL_ENV_DISABLE_PROMPT)\`"
	print - "- Conda: \`$(typeset -p CONDA_CHANGEPS1)\`"

	local ohmyzsh=0
	typeset -la frameworks
	(( $+ANTIBODY_HOME )) && frameworks+=("Antibody")
	(( $+ADOTDIR )) && frameworks+=("Antigen")
	(( $+ANTIGEN_HS_HOME )) && frameworks+=("Antigen-hs")
	(( $+functions[upgrade_oh_my_zsh] )) && {
		ohmyzsh=1
		frameworks+=("Oh My Zsh")
	}
	(( $+ZPREZTODIR )) && frameworks+=("Prezto")
	(( $+ZPLUG_ROOT )) && frameworks+=("Zplug")
	(( $+ZPLGM )) && frameworks+=("Zplugin")

	(( $#frameworks == 0 )) && frameworks+=("None")
	print - "- Detected frameworks: ${(j:, :)frameworks}"

	if (( ohmyzsh )); then
		print - "    - Oh My Zsh:"
		print - "        - Plugins: ${(j:, :)plugins}"
	fi
}

prompt_decker_setup() {
	# Prevent percentage showing up if output doesn't end with a newline.
	export PROMPT_EOL_MARK=''

	prompt_opts=(subst percent)

	# Borrowed from `promptinit`. Sets the prompt options in case Skipper was not
	# initialized via `promptinit`.
	setopt noprompt{bang,cr,percent,subst} "prompt${^prompt_opts[@]}"

	if [[ -z $prompt_newline ]]; then
		# This variable needs to be set, usually set by promptinit.
		typeset -g prompt_newline=$'\n%{\r%}'
	fi

	zmodload zsh/datetime
	zmodload zsh/zle
	zmodload zsh/parameter
	zmodload zsh/zutil

	autoload -Uz add-zsh-hook
	autoload -Uz vcs_info
	autoload -Uz async && async

	unsetopt warn_create_global

	# The `add-zle-hook-widget` function is not guaranteed to be available.
	# It was added in Zsh 5.3.
	autoload -Uz +X add-zle-hook-widget 2>/dev/null

	# Set the colors.
	typeset -gA prompt_decker_colors_default prompt_decker_colors
	prompt_decker_colors_default=(
		execution_time       yellow
		git:arrow            magenta
		git:stash            cyan
		git:branch           white
		git:branch:cached    red
		git:action           yellow
		git:dirty            red
        git:clean            green
		host                 242
		path                 green
		separator            white
		prompt:error         red
		prompt:success       white
		prompt:continuation  242
		suspended_jobs       red
		user                 242
		user:root            default
		virtualenv           242
	)
	prompt_decker_colors=("${(@kv)prompt_decker_colors_default}")

	add-zsh-hook precmd prompt_check_last_exit_code
	add-zsh-hook precmd prompt_decker_precmd
	add-zsh-hook preexec prompt_decker_preexec

	prompt_decker_state_setup

	zle -N prompt_decker_reset_prompt
	zle -N prompt_decker_update_vim_prompt_widget
	zle -N prompt_decker_reset_vim_prompt_widget
	if (( $+functions[add-zle-hook-widget] )); then
		add-zle-hook-widget zle-line-finish prompt_decker_reset_vim_prompt_widget
		add-zle-hook-widget zle-keymap-select prompt_decker_update_vim_prompt_widget
	fi

	PROMPT=${prompt_decker_state[prompt]}

	# Indicate continuation prompt by … and use a darker color for it.
	typeset -g prompt_pointer_symbol
	local prompt_simple='%F{$prompt_decker_colors[separator]}${prompt_pointer_symbol}%f '
	PROMPT2='%F{$prompt_decker_colors[prompt:continuation]}… %(1_.%_ .%_)%f'$prompt_simple

	# Store prompt expansion symbols for in-place expansion via (%). For
	# some reason it does not work without storing them in a variable first.
	typeset -ga prompt_decker_debug_depth
	prompt_decker_debug_depth=('%e' '%N' '%x')

	# Compare is used to check if %N equals %x. When they differ, the main
	# prompt is used to allow displaying both filename and function. When
	# they match, we use the secondary prompt to avoid displaying duplicate
	# information.
	local -A ps4_parts
	ps4_parts=(
		depth 	  '%F{yellow}${(l:${(%)prompt_decker_debug_depth[1]}::+:)}%f'
		compare   '${${(%)prompt_decker_debug_depth[2]}:#${(%)prompt_decker_debug_depth[3]}}'
		main      '%F{blue}${${(%)prompt_decker_debug_depth[3]}:t}%f%F{242}:%I%f %F{242}@%f%F{blue}%N%f%F{242}:%i%f'
		secondary '%F{blue}%N%f%F{242}:%i'
		prompt 	  '%F{242}>%f '
	)
	# Combine the parts with conditional logic. First the `:+` operator is
	# used to replace `compare` either with `main` or an ampty string. Then
	# the `:-` operator is used so that if `compare` becomes an empty
	# string, it is replaced with `secondary`.
	local ps4_symbols='${${'${ps4_parts[compare]}':+"'${ps4_parts[main]}'"}:-"'${ps4_parts[secondary]}'"}'

	# Improve the debug prompt (PS4), show depth by repeating the +-sign and
	# add colors to highlight essential parts like file and function name.
	PROMPT4="${ps4_parts[depth]} ${ps4_symbols}${ps4_parts[prompt]}"

	# Guard against Oh My Zsh themes overriding Skipper.
	unset ZSH_THEME

	# Guard against (ana)conda changing the PS1 prompt
	# (we manually insert the env when it's available).
	export CONDA_CHANGEPS1=no
}

prompt_decker_setup "$@"
