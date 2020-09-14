#!/usr/bin/env bash

set -euoE pipefail

HOME_BARE="$HOME/.home-bare"
HOME_BACKUP="$HOME/.home-backup"

home() {
   git --git-dir="$HOME_BARE" --work-tree="$HOME" "$@"
}

yes_or_no() {
  echo "$1"

  select yn in 'yes' 'no'; do
    case "$yn" in
      yes ) echo 'Proceeding'; break;;
      no ) echo 'Exiting'; exit;;
    esac
  done
}

yes_or_no 'Have you added your personal SSH key?'
yes_or_no 'Have you added your personal GPG key?'

git clone --bare 'git@github.com:coleleahy/home.git' "$HOME_BARE"

cd "$HOME"

echo "Cloning work tree into $HOME"

if ! home checkout
then
    echo "Backing up dirty $HOME to $HOME_BACKUP"

    mkdir -p "$HOME_BACKUP"

    set +o pipefail
    home checkout 2>&1 | \
      grep '^\s\+[a-zA-Z\.\/0-9_-]\+' | \
      sed -e "s|^\s\+|$HOME/|" | \
      xargs ls -d > /tmp/rsync-files
    set -o pipefail

    rsync \
      -dl \
      --remove-source-files \
      --delete \
      --files-from=/tmp/rsync-files \
      '/' "$HOME_BACKUP"

    echo "Backed up dirty $HOME to $HOME_BACKUP"

    home checkout
fi

echo "Cloned work tree into $HOME"

home config status.showUntrackedFiles no

"$HOME/install.sh"
