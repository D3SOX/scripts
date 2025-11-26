#!/usr/bin/env bash

# Temporarily enable developer mode for the Spotify desktop client on Linux and macOS.

showHelp () {
  echo -e \
"Usage: ./tmpdevmodify.sh [option]\n
Options:
-c, --clearcache   Clear Spotify app cache
-d, --debug        Add Debug Tools to user dropdown menu
--help             Print this help message
--remove           Remove developer mode"
}

clear="\033[0m"
red="\033[0;31m"

while getopts ':cd-:' flag; do
  case "${flag}" in
    -)
      case "${OPTARG}" in
        clearcache) clearCache='true' ;;
        debug) debug='true' ;;
        help) showHelp; exit 0 ;;
        remove) remove='true' ;;
        *) echo -e "${red}Error:${clear} '--""${OPTARG}""' not supported\n\n$(showHelp)\n" >&2; exit 1 ;;
      esac ;;
    c) clearCache='true' ;;
    d) debug='true' ;;
    \?) echo -e "${red}Error:${clear} '-""${OPTARG}""' not supported\n\n$(showHelp)\n" >&2; exit 1 ;;
  esac
done

command -v perl >/dev/null || { echo -e "\n${red}Error:${clear} perl command not found.\nInstall perl on your system then try again.\n" >&2; exit 1; }

searchCacheLinux () {
  local timeout=7
  local paths=("$HOME/.cache" "$HOME" "/")
  for path in "${paths[@]}"; do
    local path="${path}"
    local timeLimit=$(($(date +%s) + timeout))
    while (( $(date +%s) < "${timeLimit}" )); do
      cachePath=$(find "${path}" -type d -path "*cache/spotify*" -print -quit 2>/dev/null)
      [[ -n "${cachePath}" ]] && return 0
      pgrep -x find > /dev/null || break
      sleep 1
    done
  done
  return 1
}

searchPrefsLinux () {
  local timeout=7
  local paths=("$HOME/.config" "$HOME" "/")
  for path in "${paths[@]}"; do
    local path="${path}"
    local timeLimit=$(($(date +%s) + timeout))
    while (( $(date +%s) < "${timeLimit}" )); do
      prefsPath=$(find "${path}" -type f -path "*/spotify/prefs" -print -quit 2>/dev/null)
      [[ -n "${prefsPath}" ]] && return 0
      pgrep -x find > /dev/null || break
      sleep 1
    done
  done
  return 1
}

case $(uname | tr '[:upper:]' '[:lower:]') in
  darwin*) platformType='macOS' ;;
        *) platformType='Linux' ;;
esac

if [[ "${platformType}" == "macOS" ]]; then
  cachePath="${HOME}/Library/Caches/com.spotify.client"
  offlineBnk="${HOME}/Library/Application Support/Spotify/PersistentCache/offline.bnk"
  prefsPath="${HOME}/Library/Application Support/Spotify/prefs"
else
  searchCacheLinux
  offlineBnk="${cachePath}/offline.bnk"
fi

command pgrep [sS]potify 2>/dev/null | xargs kill -9 2>/dev/null
[[ "${clearCache}" ]] && { rm -rf "${cachePath}/Browser" 2>/dev/null; rm -rf "${cachePath}/Data" 2>/dev/null; rm "${cachePath}/LocalPrefs.json" 2>/dev/null; }

if [[ "${remove}" ]]; then
  [[ "${platformType}" == "Linux" ]] && searchPrefsLinux
  [[ -f "${prefsPath}" ]] && perl -pi -e 'print unless /app.enable-developer-mode=true/' "${prefsPath}"
  [[ -f "${offlineBnk}" ]] && {
    perl -pi -w -e 's|\x01\x08\x65\x6D\x70\x6C\x6F\x79\x65\x65\x09\x01\x31\x78||' "${offlineBnk}"
    perl -pi -w -e 's#\x70\x65\x72\x3E\K\x33|\x70\x65\x72\x09\x01\K\x33#\x30#g' "${offlineBnk}"
  }
  echo -e "Spotify developer options are removed until script is used again.\n"
  exit 0
fi
  
if [[ "${debug}" ]]; then
  [[ "${platformType}" == "Linux" ]] && searchPrefsLinux
  [[ ! -f "${prefsPath}" ]] && { echo -e "${red}prefs not found!${clear} Run Spotify once then try again.\n" >&2; exit 1; }
  [[ ! -f "${offlineBnk}" ]] && { echo -e "${red}offline.bnk not found!${clear} Run Spotify once then try again.\n" >&2; exit 1; }
  echo "app.enable-developer-mode=true" >> "${prefsPath}"
  perl -pi -w -e 's|\x01\x2A\x63\x6F\x6D\x2E\x73\x70\x6F\x74\x69\x66\x79\x2E\x6D\x61\x64\x70\x72\x6F\x70\x73\x2E\x75\x73\x65\x2E\x75\x63\x73\x2E\x70\x72\x6F\x64\x75\x63\x74\x2E\x73\x74\x61\x74\x65\x09\x01[\x30\x31]\x78||' "${offlineBnk}"
  perl -pi -w -e 's|\x01\x0D\x61\x70\x70\x2D\x64\x65\x76\x65\x6C\x6F\x70\x65\x72\x09\x01[\x30\x31\x32\x33]\x78|\x01\x08\x65\x6D\x70\x6C\x6F\x79\x65\x65\x09\x01\x31\x78\x01\x2A\x63\x6F\x6D\x2E\x73\x70\x6F\x74\x69\x66\x79\x2E\x6D\x61\x64\x70\x72\x6F\x70\x73\x2E\x75\x73\x65\x2E\x75\x63\x73\x2E\x70\x72\x6F\x64\x75\x63\x74\x2E\x73\x74\x61\x74\x65\x09\x01\x31\x78|' "${offlineBnk}"
else
  [[ ! -f "${offlineBnk}" ]] && { echo -e "${red}offline.bnk not found!${clear} Run Spotify once then try again.\n" >&2; exit 1; }
  perl -pi -w -e 's#\x70\x65\x72\x3E\K[\x30\x31]|\x70\x65\x72\x09\x01\K[\x30\x31]#\x33#g' "${offlineBnk}"
fi

echo -e "Finished! Spotify developer options will be enabled on next run.\n"
exit 0


