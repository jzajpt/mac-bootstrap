#!/usr/bin/env bash

main() {
  # Ask for sudo password upfront
  sudo -v

  remap_caps_lock_to_escape
  install_homebrew
  install_from_brewfile
  make_fish_default_shell
  set_macos_defaults
  update_hosts_file
  setup_dnscrypt_proxy
  configure_dock
  install_rustup
  install_dotfiles
  setup_neovim
}

function remap_caps_lock_to_escape() {
  # /Library/LaunchAgents/com.user.remap_keys.plist
  sudo cp remap_keys.sh /usr/local/bin
  sudo chmod 0755 /usr/local/bin/remap_keys.sh
  sudo chown root:wheel /usr/local/bin/remap_keys.sh

  cp com.user.remap_keys.plist $HOME/Library/LaunchAgents/

  success "CapsLock remapped to Escape!"
}

function install_homebrew() {
  if hash brew 2>/dev/null; then
    info "Homebrew already installed"
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

  # Install packages specified in Brewfile
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

  symlink_dotfile "fish_aliases"
  symlink_dotfile "fish_variables"
  symlink_dotfile "config.fish" "$HOME/.config/fish/config.fish"


  # Do not install OMF yet
  # omf_directory=~/.local/share/omf
  # if [ ! -d "$omf_directory" ]; then
  #   curl -l https://get.oh-my.fish > install-omf
  #   fish install --path=$omf_directory --config=~/.config/omf
  #   rm install-omf
  # fi
}

function set_macos_defaults() {
  set_global_defaults
  set_software_update_defaults
  set_menubar_defaults
  set_finder_defaults
  set_safari_defaults
  enable_firewall
  success "MacOS defaults set!"
}

function set_global_defaults() {
  # Close any open System Preferences panes, to prevent them from overriding
  # settings we
  osascript -e 'tell application "System Preferences" to quit'

  # Show the ~/Library folder.
  chflags nohidden ~/Library

  # Disable Guest user
  sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool FALSE

  # Use a dark menu bar / dock
  defaults write -g AppleInterfaceStyle Dark

  # Disable system sounds
  # defaults write -g com.apple.sound.uiaudio.enabled -bool false
  defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int 1

  # Don't show Siri in the menu bar
  defaults write com.apple.Siri StatusMenuVisible -bool false

  # Disable auto-correct
  defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write -g WebAutomaticSpellingCorrectionEnabled -bool false

  # Disable Dashboard
  defaults write com.apple.dashboard mcx-disabled -bool true

  # Require password immediately after sleep or screen saver begins"
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0

  # Disable crash reporter
  sudo defaults write com.apple.CrashReporter DialogType none
  launchctl unload -w /System/Library/LaunchAgents/com.apple.ReportCrash.plist
  sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist
  sudo launchctl unload -w com.apple.ReportPanic
}

function set_software_update_defaults() {
  # Enable the automatic update check
  defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

  # Download newly available updates in background
  defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

  # Install System data files & security updates
  defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
}

function set_menubar_defaults() {
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

function set_finder_defaults() {
  # Avoid creating .DS_Store files on network or USB volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  # Show all files (including dotfiles)
  defaults write com.apple.finder AppleShowAllFiles -bool true

  # Open new window to User Home
  defaults write com.apple.finder NewWindowTarget -string PfHm

  # Keep folders on top when sorting by name (restart Finder):
  defaults write com.apple.Finder _FXSortFoldersFirst -bool true

  # Restart Finder to make changes effective now
  killall -9 Finder
}

function set_safari_defaults() {
  info "Make sure the terminal has 'Full Disk Access' enabled, otherwise Safari
  settings won't work"
  info "Press ENTER to confirm."
  read

  # Safari opens with all windows from last session
  defaults write -app Safari AlwaysRestoreSessionAtLaunch -bool true

  # Enable "Do Not Track"
  defaults write -app Safari SendDoNotTrackHTTPHeader -bool true

  # Show full URLs
  defaults write -app Safari ShowFullURLInSmartSearchField -bool true


  # New tabs instead of new windows
  defaults write -app Safari TargetedClicksCreateTabs -bool true

  # Enable the Develop menu and the Web Inspector in Safari
  defaults write -app Safari IncludeDevelopMenu -bool true
  defaults write -app Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

  # Disable AutoFill
  defaults write -app Safari AutoFillPasswords -bool false

  # Restart Safari to make changes effective now
  # osascript -e 'tell application "Safari" to quit'
}

function update_hosts_file() {
  # Update hosts file to block known malware, adware etc.
  curl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts | sudo tee /etc/hosts
  sudo dscacheutil -flushcache
  sudo killall -HUP mDNSResponder
  success "Hosts file updated with "
}

function setup_dnscrypt_proxy() {
  # dnscrypt-proxy runs on 53 by defaults, so it needs to be run under root
  sudo brew services restart dnscrypt-proxy
  sudo networksetup -setdnsservers "Wi-Fi" 127.0.0.1
  success "Dnscrypt-proxy configured & running!"
}

function enable_firewall() {
  local fw="sudo /usr/libexec/ApplicationFirewall/socketfilterfw"

  # Enable the firewall
  $fw --setglobalstate on

  # Enable logging on the firewall
  $fw --setloggingmode on

  # Enable stealth mode
  # (computer does not respond to PING or TCP connections on closed ports)
  $fw --setstealthmode on

  # # Prevent built-in software as well as code-signed, downloaded software from
  # being whitelisted automatically
  $fw --setallowsigned off
  $fw --setallowsignedapp off

  # Restart the firewall (this should remain last)
  sudo pkill -HUP socketfilterfw
}

function configure_dock() {
  if ! hash dockutil 2>/dev/null; then
    error "Dockutil is not installed, but should have been already present!"
    exit 1
  fi

  dockutil --no-restart --remove all
  dockutil --no-restart --add "/Applications/System Preferences.app"
  dockutil --no-restart --add "/Applications/Safari.app"
  dockutil --no-restart --add "/Applications/Notes.app"
  dockutil --no-restart --add "/Applications/Alacritty.app"

  # Don't show recent applications in Dock
  defaults write com.apple.dock show-recents -bool false

  # Set the icon size of Dock items to 36 pixels
  defaults write com.apple.dock tilesize -int 36

  # Don't show Dashboard as a Space
  defaults write com.apple.dock dashboard-in-overlay -bool true

  # Don't automatically rearrange Spaces based on most recent use:
  defaults write com.apple.dock mru-spaces -bool false

  # Auto-hide dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0

  # Restart Dock to make changes effective now
  killall -9 Dock
}

function install_rustup() {
  rustup_directory=~/.rustup
  if [ -d "$rustup_directory" ]; then
    info "rustup already installed"
    return
  fi

  if ! hash rustup-init 2>/dev/null; then
    error "rustup-init command not present!"
    exit 1
  fi

  info "Running the rustup installer"
  # Run the rustup installer
  rustup-init

  # Add cargo's bin to $PATH using fish's universal variable
  fish -c 'set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths'

  # Install Rust Language Server
  rustup component add rls rust-analysis rust-src

  success "Rustup installed!"
}

function install_dotfiles {
  symlink_dotfile tmux.conf
  symlink_dotfile gitconfig
  symlink_dotfile init.vim $HOME/.config/nvim/init.vim
  symlink_dotfile alacritty.yml $HOME/.config/alacritty/alacritty.yml
}

function setup_neovim {
  autoload_file=$HOME/.local/share/nvim/site/autoload/plug.vim

  if [ ! -f $autoload_file ]; then
    # Install vim-plug for neovim
    curl -fLo $autoload_file --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    success "vim-plug for neovim installed"

    nvim --headless +PlugInstall +qa
    success "Neovim plugins installed"

  else
    info "vim-plug for neovim is already installed"
  fi
}

function symlink_dotfile {
  local fname="$1"
  local destination="$2"
  local dotfiles_dir=$(pwd)/dotfiles
  local default_destination=$HOME/.$fname
  local source=$dotfiles_dir/$fname
  if [ -z "$destination" ]; then
    ln -fs $source $default_destination
  else
    mkdir -p $(dirname $destination)
    ln -fs $source $destination
  fi
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

