# Fran's custom liquidprompt

LP_PS1="${LP_PS1_PREFIX}"

# add time, jobs, load and battery
local before=''
for segment in "$LP_TIME" "$LP_BATT" "$LP_LOAD" "$LP_JOBS"; do
	if [[ -n "$segment" ]]; then
		before="${before}${segment%% }${NO_COL}|"
	fi
done
if [[ -n "$before" ]]; then
	LP_PS1="${LP_PS1}${LP_BRACKET_OPEN}${before%%\|}${LP_BRACKET_CLOSE}"
fi

LP_PS1="${LP_PS1}${LP_BRACKET_OPEN}"

# add user, host, permissions colon, and PWD
LP_PS1="${LP_PS1}${LP_USER}${LP_HOST}${LP_PERM}${LP_PWD}"

local afterdir=''
for segment in "$LP_VENV" "$LP_PROXY" "$LP_VCS"; do
	if [[ -n "$segment" ]]; then
		afterdir="${afterdir}${NO_COL}|${segment## }"
	fi
done
if [[ -n "$afterdir" ]]; then
	LP_PS1="${LP_PS1}${NO_COL}<${afterdir##*\|}${NO_COL}>"
fi

LP_PS1="${LP_PS1}${LP_BRACKET_CLOSE}"

# add venv, proxy, VCS, and return code
local after=''
for segment in "$LP_RUNTIME" "$LP_ERR"; do
	if [[ -n "$segment" ]]; then
		after="${after}${NO_COL}|${segment## }"
	fi
done
if [[ -n "$after" ]]; then
	LP_PS1="${LP_PS1}${LP_BRACKET_OPEN}${after##*\|}${LP_BRACKET_CLOSE}"
fi

# add prompt mark
LP_PS1="${LP_PS1}${LP_MARK_PREFIX}${LP_MARK}${LP_PS1_POSTFIX}"

# "invisible" parts
# Get the current prompt on the fly and make it a title
#LP_TITLE="$(_lp_title "$LP_PS1")"
# Insert it in the prompt
#LP_PS1="${LP_TITLE}${LP_PS1}"

if [[ -n "$ZSH_VERSION" ]]; then
	[[ -z $precmd_functions ]] && precmd_functions=()
	[[ -z $preexec_functions ]] && preexec_functions=()

	if [[ $LP_ENABLE_SCREEN_TITLE == 1 && $TERM =~ ^screen ]]; then
		function _precmd_tmux_name {
			if [[ $SSH_TTY == `tty` ]] ; then
				print -Pn "\ek%m:(%1~)\e\\"
			else
				print -Pn "\ek(%1~)\e\\"
			fi
		}
		precmd_functions=($precmd_functions _precmd_tmux_name)
		function _preexec_tmux_name {
			if [[ $SSH_TTY == `tty` ]] ; then
				print -Pn "\ek%m:${2%% *}\e\\"
			else
				print -Pn "\ek${2%% *}\e\\"
			fi
		}
		preexec_functions=($preexec_functions _preexec_tmux_name)
	fi
	
	if [[ $LP_ENABLE_TITLE == 1 && $TERM =~ ^(xterm|rxvt|screen|putty) ]]; then
		function _precmd_xterm_title {
			print -Pn "\e]0;%n@%m: %~\a"
		}
		precmd_functions=($precmd_functions _precmd_xterm_title)
		function _preexec_xterm_title {
			print -Pn "\e]0;%n@%m: $2\a"
		}
		preexec_functions=($preexec_functions _preexec_xterm_title)
	fi
else
	local per_command=''
	local per_prompt=''

	if [[ $LP_ENABLE_SCREEN_TITLE == 1 && $TERM =~ ^screen ]]; then
		if [[ $SSH_TTY == `tty` ]]; then
			per_prompt+='\[\033k\h:(\W)\033\\\]'
			per_command+='\033k$HOSTNAME:${COMMAND%% *}\033\'
		else
			per_prompt+='\[\033k(\W)\033\\\]'
			per_command+='\033k${COMMAND%% *}\033\'
		fi
	fi

	if [[ $LP_ENABLE_TITLE == 1 && $TERM =~ ^(xterm|rxvt|screen|putty) ]]; then
		per_prompt+='\[\033]0;\u@\h: \w\007\]'
		per_command+='\033]0;${USER}@${HOSTNAME}: ${COMMAND}\007'
	fi

	if [[ -n "$per_prompt" ]]; then
		LP_PS1="$per_prompt$LP_PS1"
	fi
	if [[ -n "$per_command" ]]; then
		unset _TRAP_ONCE
		trap "if [[ -z \"\$_TRAP_ONCE\" ]]; then COMMAND=\"\${BASH_COMMAND//\\\\/\\\\\\\\}\"; echo -ne \"$per_command\"; _TRAP_ONCE=1; fi" DEBUG
	fi
fi

# vim: set ft=sh:
