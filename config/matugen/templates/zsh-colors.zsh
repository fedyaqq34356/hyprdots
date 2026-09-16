# Генерируется matugen из ~/.config/matugen/templates/zsh-colors.zsh
# Правки здесь затираются при смене обоев — менять надо шаблон.

# Подсказка из истории — цветом контура, тише основного текста.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg={{colors.outline.default.hex}}"

# Подсветка синтаксиса. Штатная палитра плагина кричит чистыми ANSI-цветами
# на каждом слове; здесь цветом отмечено только то, что меняет смысл строки:
# неизвестная команда, кавычки, подстановка. Остальное — оттенки текста.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg={{colors.on_surface.default.hex}}"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg={{colors.error.default.hex}}"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg={{colors.tertiary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[alias]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[suffix-alias]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[global-alias]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[builtin]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[function]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[command]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[precommand]="fg={{colors.primary.default.hex}},italic"
ZSH_HIGHLIGHT_STYLES[commandseparator]="fg={{colors.outline.default.hex}}"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[path]="fg={{colors.on_surface.default.hex}},underline"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg={{colors.outline.default.hex}}"
ZSH_HIGHLIGHT_STYLES[path_prefix]="fg={{colors.on_surface_variant.default.hex}},underline"
ZSH_HIGHLIGHT_STYLES[globbing]="fg={{colors.tertiary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[history-expansion]="fg={{colors.tertiary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg={{colors.on_surface_variant.default.hex}}"
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg={{colors.on_surface_variant.default.hex}}"
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg={{colors.tertiary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg={{colors.secondary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg={{colors.secondary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg={{colors.secondary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]="fg={{colors.tertiary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]="fg={{colors.tertiary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[assign]="fg={{colors.on_surface.default.hex}}"
ZSH_HIGHLIGHT_STYLES[redirection]="fg={{colors.outline.default.hex}}"
ZSH_HIGHLIGHT_STYLES[comment]="fg={{colors.outline.default.hex}},italic"
ZSH_HIGHLIGHT_STYLES[named-fd]="fg={{colors.on_surface_variant.default.hex}}"
ZSH_HIGHLIGHT_STYLES[arg0]="fg={{colors.primary.default.hex}}"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg={{colors.error.default.hex}}"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg={{colors.on_surface_variant.default.hex}}"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg={{colors.on_surface_variant.default.hex}}"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg={{colors.on_surface_variant.default.hex}}"

# fzf. bg:-1 и gutter:-1 — цвет терминала, а не сплошная заливка: иначе
# окно поиска становится непрозрачным пятном поверх прозрачного kitty.
export FZF_DEFAULT_OPTS="
  --color=bg:-1,bg+:{{colors.surface_container_high.default.hex}},gutter:-1
  --color=fg:{{colors.on_surface_variant.default.hex}},fg+:{{colors.on_surface.default.hex}}
  --color=hl:{{colors.primary.default.hex}},hl+:{{colors.primary.default.hex}}
  --color=info:{{colors.outline.default.hex}},prompt:{{colors.primary.default.hex}}
  --color=pointer:{{colors.primary.default.hex}},marker:{{colors.tertiary.default.hex}}
  --color=spinner:{{colors.tertiary.default.hex}},header:{{colors.outline.default.hex}}
  --color=border:{{colors.outline_variant.default.hex}},label:{{colors.on_surface_variant.default.hex}}
  --color=query:{{colors.on_surface.default.hex}},separator:{{colors.outline_variant.default.hex}}
  --color=scrollbar:{{colors.outline_variant.default.hex}}
  --layout=reverse --height=45% --border=none
  --prompt='  ' --pointer='▌' --marker='▌' --info=right
  --padding=1,2 --gap=0
  --preview-window=border-left
  --bind ctrl-u:preview-up,ctrl-d:preview-down"
