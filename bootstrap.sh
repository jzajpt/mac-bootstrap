#!/usr/bin/env bash

main() {
  # Ask for sudo password upfront
  sudo -v

  remap_caps_lock_to_escape
  install_homebrew
  install_from_brewfile
  make_fish_default_shell
  set_macos_defaults
  set_dock_applications
  configure_mackup
}

function remap_caps_lock_to_escape() {
  FROM='"HIDKeyboardModifierMappingSrc"'
  TO='"HIDKeyboardModifierMappingDst"'
  
  ARGS=""
  function Map # FROM TO
  {
      CMD="${CMD:+${CMD},}{${FROM}: ${1}, ${TO}: ${2}}"
  }
  
  # Referencing :
  # https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-1035.41.2/IOHIDFamily/IOHIDUsageTables.h.auto.html
  SECTION="0x700000064"
  ESCAPE="0x700000029"
  BACKQUOTE="0x700000035"
  CAPS_LOCK="0x700000039"
  L_SHIFT="0x7000000E1"
  R_COMMAND="0x7000000E7"
  L_CONTROL="0x7000000E0"
  
  Map ${CAPS_LOCK} ${ESCAPE}
  #Map ${SECTION} ${ESCAPE}
  #Map ${R_COMMAND} ${SHIFT_LOCK}
  #Map ${BACKQUOTE} ${L_CONTROL}
  
  hidutil property --set "{\"UserKeyMapping\":[${CMD}]}"
}

function install_homebrew() {
  if hash brew 2>/dev/null; then
    success "Homebrew already installed"
  else
    url=https://raw.githubusercontent.com/Homebrew/install/master/install
    if /usr/bin/ruby -e "$(curl -fsSL ${url})"; then
      success "Homebrew installed!"
    else
      error "Homebrew installation failed!"
      exit 1
    fi
  fi
}

function install_from_brewfile() {
  # brew services is automatically installed when run.
  brew services > /dev/null 2>&1
  success "Brew services installed!"

  brew bundle
  success "Brewfile packages installed!"
}

function make_fish_default_shell() {
  fish_shell="/usr/local/bin/fish"
  config="/etc/shells"
  user=$USER
  current_shell=$(finger $user | grep 'Shell: *' | cut -f3 -d ":" | xargs)
  if [ ! $(grep $fish_shell $config) ]; then 
    echo "$fish_shell" | sudo tee -a $config
  fi
  if [ "$current_shell" != "$fish_shell" ]; then
    sudo chsh -s `which fish` $user
    success "Default shell changed to fish!"
  fi

  curl -L https://get.oh-my.fish > install
  fish install --path=~/.local/share/omf --config=~/.config/omf

}


function set_macos_defaults() {
  set_global_defaults
  set_menubar_defaults
  set_dock_defaults
  set_finder_defaults
  set_safari_defaults
  success "MacOS defaults set!"
}

function set_global_defaults() {
  # Disable Guest user
  sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool FALSE

  # Use a dark menu bar / dock
  defaults write -g AppleInterfaceStyle Dark

  # Disable system sounds
  defaults write -g com.apple.sound.uiaudio.enabled -bool false
  
  # Don't show Siri in the menu bar
  defaults write com.apple.Siri StatusMenuVisible -bool false

  # Disable auto-correct
  defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
}

set_menubar_defaults() {
  defaults write com.apple.systemuiserver menuExtras -array  \
    "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
    "/System/Library/CoreServices/Menu Extras/Clock.menu"  \
    "/System/Library/CoreServices/Menu Extras/Displays.menu" \
    "/System/Library/CoreServices/Menu Extras/Volume.menu"

  # Restart SystemUIServer for changes to take effect
  killall SystemUIServer
}

function enable_night_shift() {
  CORE_BRIGHTNESS="/var/root/Library/Preferences/com.apple.CoreBrightness.plist"
  
  ENABLE='{
    CBBlueReductionStatus =     {
      AutoBlueReductionEnabled = 1;
      BlueLightReductionDisableScheduleAlertCounter = 3;
      BlueLightReductionSchedule =         {
        DayStartHour = 8;
        DayStartMinute = 0;
        NightStartHour = 22;
        NightStartMinute = 0;
      };
      BlueReductionEnabled = 0;
      BlueReductionMode = 1;
      BlueReductionSunScheduleAllowed = 1;
      Version = 1;
    };
  }'
  
  defaults write $CORE_BRIGHTNESS "CBUser-0" "$ENABLE"
  defaults write $CORE_BRIGHTNESS "CBUser-$(dscl . -read $HOME GeneratedUID | sed 's/GeneratedUID: //')" "$ENABLE"
}

function set_dock_defaults() {
  # Don’t show recent applications in Dock
  defaults write com.apple.dock show-recents -bool false

  # Set the icon size of Dock items to 36 pixels
  defaults write com.apple.dock tilesize -int 36

  # Disable Dashboard
  defaults write com.apple.dashboard mcx-disabled -bool true

  # Don’t show Dashboard as a Space
  defaults write com.apple.dock dashboard-in-overlay -bool true

  # Restart Dock to make changes effective now
  killall -9 Dock
}

function set_finder_defaults() {
  # Avoid creating .DS_Store files on network or USB volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  # Restart Finder to make changes effective now
  killall -9 Finder
}

function set_safari_defaults() {
  container="~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari"

  # Create container file first
  mkdir -p `dirname $container`
  touch $container

  defaults write $container AlwaysRestoreSessionAtLaunch -bool true

  # Enable Safari’s debug menu
  defaults write $container SendDoNotTrackHTTPHeader -bool true

  # Use DuckDuckGo as default search engine
  defaults write $container NSPreferredWebServices '{
  NSWebServicesProviderWebSearch = {
    NSDefaultDisplayName = DuckDuckGo;
    NSProviderIdentifier = "com.duckduckgo";
  };
}'

  # Restart Safari to make changes effective now
  # killall -9 Safari
}

set_dock_applications() {
  if ! hash dockutil 2>/dev/null; then
    error "Dockutil is not installed, but should have been already present!"
    exit 1
  fi

  dockutil --no-restart --remove all
  dockutil --no-restart --add "/Applications/System Preferences.app"
  dockutil --no-restart --add "/Applications/Safari.app"
  dockutil --no-restart --add "/Applications/Notes.app"
  dockutil --no-restart --add "/Applications/Alacritty.app"

  # Restart Dock to make changes effective now
  killall -9 Dock
}

function configure_mackup() {
  cp mackup.cfg ~/.mackup.cfg
}

function colored_echo() {
    local exp="$1";
    local color="$2";
    local arrow="$3";
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput bold;
    tput setaf "$color";
    echo "$arrow $exp";
    tput sgr0;
}

function info() {
    colored_echo "$1" blue "========>"
}

function substep() {
    colored_echo "$1" magenta "===="
}

function success() {
    colored_echo "$1" green "========>"
}

function error() {
    colored_echo "$1" red "========>"
}

main "$@"

