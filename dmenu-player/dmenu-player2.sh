#!/usr/bin/env bash

video_dir="$HOME/Videos"
dmenu_player="$(find "${video_dir}" -iname "*.avi")"

main() {
  choice=$(printf '%s\n' "${dmenu_player[@]}" | \
      cut -d '/' -f5- | \
      sed -e 's/.avi//g'| \
      sort | \
      dmenu -i -l 20 -p 'My Videos:') || exit 1
  if [ "$choice" ]; then
      vlc "${video_dir}/${choice}.avi"
  else
      echo "No video selected"
  fi
  
}

main


