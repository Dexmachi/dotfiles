workon() {
  local project_dir=~/projetos
  local project

  while true; do
    project=$(fd --base-directory="$project_dir" -d 1 -t d | fzf --header="Selecione um projeto existente." \
      --preview "eza -T -a --icons --level=2 --color=always $project_dir$realpath/{}" \
      --preview-window=right:70%)

    if [[ -d "$project_dir/$project" && -n "$project" ]]; then
      echo "entrou no projeto: $project"
      cd && cd "$project_dir/$project" && nvim .
      break
    fi

    echo "projeto inválido"
    break
  done
}

newWorkon() {
  local project_dir=~/projetos
  local project
  local full_path

  mkdir -p "$project_dir"

  while true; do
    project=$(fd --base-directory="$project_dir" -d 1 -t d | fzf \
      --preview "eza -T --icons --level=2 --color=always $project_dir$realpath/{}" \
      --preview-window=right:70% \
      --header="Digite para criar um novo projeto." \
      --print-query \
      --multi | tail -n 1)

    [[ -z "$project" ]] && echo "Cancelado." && return

    full_path="$project_dir/$project"

    if [[ -d "$full_path" ]]; then
      echo "Projeto já existe: $project"
    else
      mkdir -p "$full_path"
      echo "Criado novo projeto: $project"
      cd && cd "$full_path" && nvim .
    fi
    break
  done
}

newWorkonGum() {
  figlet -f smslant "Projetos"
  local project_dir=~/projetos
  local choice
  local project

  mkdir -p "$project_dir"

  # 1. Pergunta ao usuário qual ação deseja realizar com `gum choose`
  choice=$(gum choose "📂 Selecionar projeto existente" "✨ Criar novo projeto")

  # 2. Executa a lógica baseada na escolha
  case "$choice" in
  "📂 Selecionar projeto existente")
    workon
    ;;

  "✨ Criar novo projeto")
    # Usa `gum input` para obter o nome do novo projeto
    newWorkon
    ;;

  *)
    # Caso o usuário cancele a escolha inicial
    echo "❌ Operação cancelada."
    return 1
    ;;
  esac
}

alias dprj='newWorkonGum'

# utilitários nushell
nls() {
  nu -c "ls $*"
}

nll() {
  nu -c "ls -l $* "
}

dtj() {
  nu -c "open $1 | to json" | nvim -c 'set ft=json'
}

dty() {
  nu -c "open $1 | to yaml" | nvim -c 'set ft=yaml'
}

dtt() {
  nu -c "open $1 | to toml" | nvim -c 'set ft=toml'
}

dtc() {
  nu -c "open $1 | to csv" | nvim -c 'set ft=csv'
}

dtts() {
  nu -c "open $1 | to tsv" | nvim -c 'set ft=tsv'
}

nop() {
  nu -c "open '$1' | select ${*:2}"
}

ns() {
  nu -c "$*"
}
