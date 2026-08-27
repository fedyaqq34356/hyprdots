export PATH="$HOME/.local/bin:$PATH"

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory histignorealldups sharehistory incappendhistory histignorespace

# история: строки с секретами в неё не попадают вовсе
zshaddhistory() {
	emulate -L zsh
	setopt localoptions extendedglob
	local line=${1%%$'\n'}
	local lower=${line:l}
	case "$lower" in
		*token*|*password*|*passwd*|*secret*|*api[-_]key*|*apikey*|*bearer*|\
		*authorization*|*private[-_]key*|*access[-_]key*|*client[-_]secret*|\
		*sk-ant-*|*ghp_*|*github_pat_*|*aws_secret*|*bot[0-9]*:aa*)
			return 1 ;;
	esac
	return 0
}

# «секретная» сессия: ничего из неё не остаётся на диске
secret() {
	HISTFILE= HISTSIZE=0 SAVEHIST=0 LESSHISTFILE=- \
	PYTHONHISTFILE=/dev/null NODE_REPL_HISTORY=/dev/null \
	zsh -f -i
}

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(starship init zsh)"

eval "$(zoxide init zsh)"

source /usr/share/fzf/key-bindings.zsh 2>/dev/null
source /usr/share/fzf/completion.zsh   2>/dev/null
export FZF_DEFAULT_OPTS="
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=selected-bg:#45475a
  --border rounded --padding 1 --height 50%
  --bind ctrl-u:preview-up,ctrl-d:preview-down"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}' 2>/dev/null"

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    local cwd="$(cat -- "$tmp")"
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd "$cwd"
    rm -f "$tmp"
}

alias lg='lazygit'
alias ls='eza --icons --group-directories-first'
alias ll='eza --icons --group-directories-first -l --git'
alias la='eza --icons --group-directories-first -la --git'
alias lt='eza --icons --tree --level=2'
alias cat='bat --style=plain'
alias catn='bat'
alias grep='rg'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -p'
alias cp='cp -i'
alias mv='mv -i'
alias cls='clear'

export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
export PATH="$HOME/bin:$PATH"

# секреты живут в файле 600, а не в конфиге оболочки
[[ -r "$HOME/.config/secrets/env" ]] && source "$HOME/.config/secrets/env"

# истории интерпретаторов и пейджера рядом с остальным состоянием, не в $HOME
export LESSHISTFILE=-
export PYTHONHISTFILE="$HOME/.local/state/python_history"
export NODE_REPL_HISTORY="$HOME/.local/state/node_repl_history"
export SQLITE_HISTORY="$HOME/.local/state/sqlite_history"
mkdir -p "$HOME/.local/state" 2>/dev/null

# телеметрия тулчейнов и утилит — выключена
export DO_NOT_TRACK=1
export NEXT_TELEMETRY_DISABLED=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export GATSBY_TELEMETRY_DISABLED=1
export NUXT_TELEMETRY_DISABLED=1
export ASTRO_TELEMETRY_DISABLED=1
export STORYBOOK_DISABLE_TELEMETRY=1
export SAM_CLI_TELEMETRY=0
export AZURE_CORE_COLLECT_TELEMETRY=0
export HOMEBREW_NO_ANALYTICS=1
export CHECKPOINT_DISABLE=1
export TERRAFORM_TELEMETRY=0
export INFLUXD_REPORTING_DISABLED=true
export ADBLOCK=1
export HINT_TELEMETRY=off
export GOTELEMETRY=off
export PIP_DISABLE_PIP_VERSION_CHECK=1
export npm_config_fund=false
export npm_config_audit=false
export NG_CLI_ANALYTICS=false
export VUE_CLI_TELEMETRY=false
export ELECTRON_ENABLE_LOGGING=0

# core dump'ы никуда не пишутся из интерактивной оболочки
ulimit -c 0
