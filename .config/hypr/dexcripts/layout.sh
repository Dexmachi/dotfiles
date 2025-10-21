#!/usr/bin/env bash

# Função para definir o layout com base no ID do workspace
set_layout_for_workspace() {
  local workspace_id=$1

  # Lógica para definir o layout. Adicione mais 'case' conforme necessário.
  case $workspace_id in
  1)
    hyprctl keyword general:layout master
    ;;
  2)
    hyprctl keyword general:layout dwindle
    ;;
  3)
    hyprctl keyword general:layout dwindle
    ;;
  4)
    # Para todos os outros workspaces, reverte para um layout padrão (ex: dwindle)
    hyprctl keyword general:layout dwindle
    ;;
  5) ;;
  *)
    hyprctl keyword general:layout master
    ;;
  esac
}

# Escuta eventos de 'workspace' do socket IPC do Hyprland usando o caminho correto
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  # Verifica se a linha recebida é um evento de mudança de workspace
  if [[ $line == "workspace>>"* ]]; then
    # Extrai o ID do workspace do evento. Ex: "workspace>>1" -> "1"
    active_workspace_id=$(echo "$line" | cut -d '>' -f 3)
    set_layout_for_workspace "$active_workspace_id"
  fi
done
