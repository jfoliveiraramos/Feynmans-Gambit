#!/bin/bash

# Header text
read -r -d '' HEADER <<'EOF'
Branches' Gambit Copyright (C) 2025 João Ramos

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.
EOF

# File extensions to target
EXTENSIONS=("zig" "gleam" "rs" "go" "svelte")

# Convert header to comment based on file type
function comment_header() {
    local ext="$1"
    local comment=""
    while IFS= read -r line; do
        case "$ext" in
        zig | gleam | rs | go)
            comment+="// $line"$'\n'
            ;;
        svelte)
            comment+="<!-- $line -->"$'\n'
            ;;
        esac
    done <<<"$HEADER"
    echo "$comment"
}

# Check and prepend header
for ext in "${EXTENSIONS[@]}"; do
    find . -type f -name "*.$ext" \
        -not -path "*/.zig-cache/*" \
        -not -path "*/zig-out/*" \
        -not -path "*/target/*" \
        -not -path "*/node_modules/*" | while read -r file; do
        if ! grep -q "Branches' Gambit Copyright" "$file"; then
            tmpfile=$(mktemp)
            comment_header "$ext" >"$tmpfile"
            cat "$file" >>"$tmpfile"
            mv "$tmpfile" "$file"
            echo "Header added to $file"
        fi
    done
done
