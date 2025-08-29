workon() {
  local project_dir=~/projetos
  local project

  while true; do
    project=$(fd --base-directory="$project_dir" -d 1 -t d | fzf --header="Selecione um projeto existente." \
      --preview "eza -T -a --icons --level=2 --color=always $project_dir$realpath/{}" \
      --preview-window=right:70%)

    if [[ -d "$project_dir/$project" && -n "$project" ]]; then
      echo "entrou no projeto: $project"
      nvim "$project_dir/$project"
      break
    fi

    echo "projeto inválido"
    break
  done
}

alias dprj='workon'

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
      --print-query | tail -n 1)

    [[ -z "$project" ]] && echo "Cancelado." && return

    full_path="$project_dir/$project"

    if [[ -d "$full_path" ]]; then
      echo "Projeto já existe: $project"
    else
      mkdir -p "$full_path"
      echo "Criado novo projeto: $project"
      nvim "$full_path"
    fi
    break
  done
}

alias dcp='newWorkon'

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
