#!/usr/bin/env bash

vd_dir="$HOME/Videos"
dmenu_player="$(find ${vd_dir} -iname "*.mp4")"

main() {
  choice=$(printf '%s\n' "${dmenu_player[@]}" | \
      cut -d '/' -f5- | \
      sed -e 's/.mp4//g'| \
      sort | \
      dmenu -i -l 20 -p 'My Videos:') || exit 1
  if [ "$choice" ]; then
      vlc "${vd_dir}/${choice}.mp4"
  else
      echo "No video selected"
  fi
  
}

main


