export PATH="$HOME/.local/bin:$PATH"

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory histignorealldups sharehistory incappendhistory histignorespace

zshaddhistory() {
	emulate -L zsh
	local line=${1%%$'\n'}
	if [[ "$line" == *(TOKEN|PASSWORD|SECRET|API_KEY|APIKEY|Authorization|BEARER)*=* || "$line" == *Bearer\ * || "$line" == *(token|password|secret)=* ]]; then
		return 1
	fi
	return 0
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
