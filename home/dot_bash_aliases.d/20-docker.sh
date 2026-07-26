# Docker / docker compose — server profile only

alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dcp='docker compose pull'
alias dprune='docker system prune -f'

alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
