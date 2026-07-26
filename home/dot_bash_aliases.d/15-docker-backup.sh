# Docker volume backup/restore — both profiles (workstation runs local
# containers too, not just the server stacks). Uses a throwaway alpine
# container to tar a volume to/from $DOCKER_BACKUP_DIR. Not a substitute
# for real off-host backups, just a quick way to snapshot before touching
# something. Every volume backs up/restores under a fixed
# "$DOCKER_BACKUP_DIR/<volume>.tar.gz" name, so `--all` can round-trip
# without a manifest — that's also why plain `dbackup <volume>` overwrites
# any previous backup of that volume rather than timestamping.

DOCKER_BACKUP_DIR="${DOCKER_BACKUP_DIR:-$HOME/docker-backups}"

dbackup() {
    if [ "$1" = "-all" ] || [ "$1" = "--all" ]; then
        local vol
        docker volume ls -q | while read -r vol; do
            dbackup "$vol"
        done
        return
    fi

    local vol="$1" dest="$2"
    if [ -z "$vol" ]; then
        echo "usage: dbackup <volume>|--all [destination.tar.gz]" >&2
        return 1
    fi
    dest="${dest:-$DOCKER_BACKUP_DIR/${vol}.tar.gz}"
    mkdir -p "$(dirname "$dest")"
    docker run --rm \
        -v "${vol}:/volume:ro" \
        -v "$(cd "$(dirname "$dest")" && pwd):/backup" \
        alpine tar czf "/backup/$(basename "$dest")" -C /volume . \
        && echo "dbackup: ${vol} -> ${dest}"
}

drestore() {
    if [ "$1" = "-all" ] || [ "$1" = "--all" ]; then
        local f vol
        for f in "$DOCKER_BACKUP_DIR"/*.tar.gz; do
            [ -f "$f" ] || continue
            vol="$(basename "$f" .tar.gz)"
            drestore "$vol" "$f"
        done
        return
    fi

    local vol="$1" src="$2"
    if [ -z "$vol" ] || [ -z "$src" ]; then
        echo "usage: drestore <volume> <backup.tar.gz> | drestore --all" >&2
        return 1
    fi
    if [ ! -f "$src" ]; then
        echo "drestore: no such file: $src" >&2
        return 1
    fi
    docker volume create "$vol" >/dev/null
    docker run --rm \
        -v "${vol}:/volume" \
        -v "$(cd "$(dirname "$src")" && pwd):/backup" \
        alpine tar xzf "/backup/$(basename "$src")" -C /volume \
        && echo "drestore: ${src} -> ${vol}"
}
