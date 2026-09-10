#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s PUBLIC_KEY_FILE TITLE\n' "$0" >&2
  exit 2
}

[[ $# -eq 2 ]] || usage
public_file=$1
title=$2

[[ -f $public_file ]] || {
  printf 'Public key file not found\n' >&2
  exit 1
}
[[ -n $title ]] || {
  printf 'Title must not be empty\n' >&2
  exit 1
}
command -v gh >/dev/null || {
  printf 'gh is required\n' >&2
  exit 1
}

# Read public material only. Never replace this with a private-key path.
public_key=$(awk 'NF { sub(/\r$/, ""); print; exit }' "$public_file")
key_material=$(printf '%s\n' "$public_key" | awk '{ print $1 " " $2 }')
[[ $key_material != " " ]] || {
  printf 'Invalid public key\n' >&2
  exit 1
}

account=$(gh api user --jq '.login')
found_id=''
found_title=''
found_material=''

while IFS=$'\t' read -r id existing_title existing_key; do
  [[ -n $id ]] || continue
  existing_material=$(printf '%s\n' "$existing_key" | awk '{ print $1 " " $2 }')

  if [[ $existing_material == "$key_material" || $existing_title == "$title" ]]; then
    found_id=$id
    found_title=$existing_title
    found_material=$existing_material
    break
  fi
done < <(gh api --paginate user/keys \
  --jq '.[] | [(.id | tostring), .title, .key] | @tsv')

if [[ -z $found_id ]]; then
  gh ssh-key add "$public_file" --title "$title"
  printf 'Added SSH key to %s\n' "$account"
elif [[ $found_title == "$title" && $found_material == "$key_material" ]]; then
  printf 'SSH key already up to date on %s\n' "$account"
else
  gh api --method PATCH "user/keys/$found_id" \
    -f "title=$title" \
    -f "key=$public_key" \
    --silent
  printf 'Updated SSH key on %s\n' "$account"
fi
