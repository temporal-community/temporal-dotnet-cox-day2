default:
    @just --list

# Register the track slug with Instruqt (first time only)
create:
    #!/usr/bin/env bash
    set -euo pipefail
    slug=$(grep -E '^slug:' instruqt/track.yml | head -1 | awk '{print $2}' | tr -d '"')
    title=$(grep -E '^title:' instruqt/track.yml | head -1 | sed -E 's/^title:[[:space:]]*//' | sed -E 's/^"(.*)"$/\1/')
    tmp=$(mktemp -d)
    (cd "$tmp" && instruqt track create "$slug" --title "$title")
    rm -rf "$tmp"
    echo "Registered slug '$slug'. Next: 'just init'."

# Push track for the first time and pull back generated IDs
init:
    cd instruqt && instruqt track push --force
    @echo ""
    @echo "instruqt/track.yml now has an assigned 'id:'. Commit it:"
    @echo "    git add instruqt/ && git commit -m 'Pin Instruqt track and tab ids'"

# Push track changes to Instruqt
push:
    cd instruqt && instruqt track push

# Pull latest state from Instruqt (captures generated IDs)
pull:
    cd instruqt && instruqt track pull

# Validate track structure
validate:
    cd instruqt && instruqt track validate

# Remove any .remote conflict files
clean-remote:
    find instruqt/ -name "*.remote" -delete
