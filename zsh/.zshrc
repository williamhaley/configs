eval `ssh-agent -s`

# Load Git completion
zstyle ':completion:*:*:git:*' script $CONFIGS_DIR/zsh/git-completion.zsh
autoload -Uz compinit && compinit -d $HOME/.zcompdump

# Custom script from a random internet user, but I like it
source ${CONFIGS_DIR}/zsh/zsh-git-prompt.sh
PROMPT='%m%~%b $(git_super_status) %# '

# ctrl + k, ctrl + a, etc., have issues in tmux with zsh. Fix it.
bindkey -e

export HISTTIMEFORMAT="[%F %T] "
export SAVEHIST=100000000
export HISTFILE=$HOME/.zsh_history
export HISTFILESIZE=1000000000
export HISTSIZE=1000000000
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY

source $HOME/.zshrc

# Append system paths to end of $PATH
PATH=$PATH:/opt/bin
PATH=$PATH:/opt/local/bin
PATH=$PATH:/opt/local/sbin
PATH=$PATH:/sbin
PATH=$PATH:/usr/local/bin

# Prepend trusted user paths to start of $PATH
PATH=$HOME/bin:$PATH
PATH=$HOME/.local/bin:$PATH
PATH=$CONFIGS_DIR/bin:$PATH

# Append untrusted paths to the end of $PATH
PATH=$PATH:$HOME/.yarn/bin

# GOLANG
PATH=$HOME/dev/go/bin:$PATH
export GOPATH=$HOME/dev/go
if go -v >/dev/null 2>&1;
then
	PATH=$PATH:$(go env GOPATH)/bin
fi

# Could also wrap this up into a function if that makes more sense.
if [ "$(uname)" != "Darwin" ]; then
	case "$TERM" in
		screen*) PROMPT_COMMAND='echo -ne "\033k\033\0134"'
	esac

	alias linux-set-time='sudo /usr/sbin/ntpdate pool.ntp.org && sudo hwclock --systohc'
	alias tree="ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'"
	# alias battery="upower -i $(upower -e | grep BAT) | grep --color=never -E percentage|xargs|cut -d' ' -f2|sed s/%//"

	export IS_LINUX=true
else
	# Let homebrew vim supercede macOS vim
	PATH=/usr/local/opt/vim/bin:$PATH

	# Enable colors.
	export CLICOLOR=1
	# Light background.
	#export LSCOLORS=ExFxCxDxBxegedabagacad
	# Dark background.
	export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

	export IS_MAC=true
fi

