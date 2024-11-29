#!/usr/bin/env sh

# This script captures keyboard events on popular POSIX Shells.
#
# Run it by executing ./answer.sh and press the arrow keys
# to see the capture exemple. Press Return to exit.
#
# It has been tested on:
#  - Windows (Git Bash and MSYS+Mintty)
#  - OS X (native terminal, Yosemite)
#  - Linux (Ubuntu dash and bash)
#
# It should work on other POSIX compatible shells like zsh and ksh
# just fine.
#
# It is somewhat reusable, just change or redeclare the answer_keypress
# function with your own bindings.
#
# Capturing code was inspired by http://www.mtxia.com/js/Downloads/Scripts/Korn/Functions/visualSelect/index.shtml

# Enables word split on zsh
setopt SH_WORD_SPLIT >/dev/null 2>&1 || :

# -e exits on any untreated error
# -u exits on any undeclared variable
# -f disables pathname expansion
set -euf

ANSWER_E=$(printf '\e')
ANSWER_ESC="$(printf '\033')"
ANSWER_RET=$(printf '\r')
ANSWER_LFD=$(printf '\n')
ANSWER_TAB=$(printf '\t')
ANSWER_BKS=$(printf '\b')
ANSWER_DEL=$(printf '\127')

answer_char ()
{
	IFS='' read -n1 -r $1 2>/dev/null
}

answer_key ()
{
	answer_reply=''
	answer_char C1

	# Detects the beginning of an escape sequence
	if [ "_${C1}_" = "_${ANSWER_E}_" ] || [ "_${C1}_" = "_${ANSWER_ESC}_" ]
	then

		C1="${ANSWER_E}"
		answer_char C2

		# Start buffering escapes
		if [ "_${C2}_" = "_[_" ]
		then
			answer_char C3

			case "_${C3}_" in
				_[0-9]_ ) # home, end, pgup, pgdown, etc
					answer_char C4
					answer_reply="${C1}${C2}${C3}${C4}"

					case "_${C4}_" in
						_[0-9]_ ) # function keys, etc
							answer_char C5
							answer_reply="${C1}${C2}${C3}${C4}${C5}"

							;;
						* )
							answer_reply="${C1}${C2}${C3}${C4}"
							;;
					esac
					;;
				* )
					# Arrow keys
					answer_reply="${C1}${C2}${C3}"
					;;
			esac
		else
			# Unspecified escape
			answer_reply="${C1}${C2}"
		fi

	elif [ "_${C1}" = "_${ANSWER_RET}" ]
	then
		answer_reply="${ANSWER_RET}"

	elif [ "_${C1}" = "_${ANSWER_LFD}" ]
	then
		answer_reply="${ANSWER_RET}"

	elif [ "_${C1}" = "_${ANSWER_BKS}" ]
	then
		answer_reply="${ANSWER_BKS}"

	elif [ "_${C1}" = "_${ANSWER_TAB}" ]
	then
		answer_reply="${C1}"

	else
		answer_reply="${C1}"
	fi

	printf %s "${answer_reply}"
}


answer_events ()
{
	# Checks if stty is available
	nostty=0
	stty -g >/dev/null 2>&1 || nostty=1
	
	printf '\033[?25l' # Hide cursor
	printf %s 'Press Arrow Keys: '
	
	trap "answer_end; exit" 2 # Restores terminal settings upon exit
	
	# Store terminal settings if stty is available
	[ $nostty = 1 ] || oldstty="$(stty -g || echo 1)"
	# Changes terminal settings to raw
	[ $nostty = 1 ] || stty raw -echo -isig -ixon -ixoff time 0 2>/dev/null || printfix=1
	while true; do
		[ $nostty = 1 ] && printf '\033[s' # Save cursor position
		keypressed="$( answer_key )"       # Get another key escape
		[ $nostty = 1 ] && printf '\033[u' # Restore cursor position
		case _"$keypressed" in
			_"${ANSWER_RET}" | _"${ANSWER_LFD}" ) # Return Key
				answer_keypress "${ANSWER_RET}" || return
				;;
			_"${ANSWER_BKS}" | _"${ANSWER_DEL}" | _"${ANSWER_E}[3~" ) # Delete Key
				answer_keypress "${ANSWER_BKS}" || return
				;;
			* )
				answer_keypress "$keypressed" || return
				;;
		esac
	done
	printf '\033[?25h' # Show cursor again
}

answer_end ()
{
	[ $nostty = 1 ] || stty "$oldstty"
}

answer_keypress ()
{
#	echo "";printf %s "$1" | od -An -t dC | head -n1;echo "" # Enable this to see ASCII codes
	case _"$1" in
		_"${ANSWER_E}${ANSWER_E}" )
			printf %s "Double ESC"
			;;
		_"${ANSWER_E}[A" ) # Key Up
			printf %s "Up"
			;;
		_"${ANSWER_E}[B" ) # Key Down
			printf %s "Down"
			;;
		_"${ANSWER_E}[C" ) # Key Right
			printf %s "Right"
			;;
		_"${ANSWER_E}[D" ) # Key Left
			printf %s "Left"
			;;
		_"${ANSWER_RET}" ) # Return Key
			[ $nostty = 1 ] && printf '\033[1A'
			printf %s\\n "Return pressed, bye!"
			answer_end
			return 1
			;;
		_"${ANSWER_BKS}" ) # Delete Key
			printf %s "Delete"
			;;
		* )
			#printf %s "$1"  1>&2
			;;
	esac
}

answer_events
