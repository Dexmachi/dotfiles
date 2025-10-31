# Minhas dotfiles para arch linux + hyprland

- completo com configuração kitty e multi layout

baseado no [ML4W](https://www.ml4w.com/)

como usar:
clone o Ch-aronte e coloque isso aqui em um Ch-obolo qualquer
```yaml
dotfiles:
  - repo: this repo
    manager: charonte
    managed:
      - source: "zsh"
        open: true
      - source: "bash"
        open: true
      - source: "walls"
        open: true
      - source: ".config"

users:
  - name: your-username
    shell: "zsh"
    groups:
      - wheel
      - input
```

rode os comandos de -> aplicar pacotes, aplicar users e aplicar dotfiles _nessa sequência_
