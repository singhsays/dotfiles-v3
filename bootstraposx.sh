#!/usr/bin/env bash

# This is my bootstrap script to install basic software and configure a
# fresh installed macbook to my liking.
# 
# Usage: curl -fsSL https://raw.githubusercontent.com/singhsays/dotfiles-v3/master/bootstraposx.sh [hostname] | bash

HOSTNAME="${1:-snapdragon}"
LOGFILE="${HOME}/bootstrap.log"
TEMPDIR=$(mktemp -d)
DOTFILESREPO="git@github.com:singhsays/dotfiles-v3.git"
SUBLIME_PREF_ROOT="${HOME}/Library/Application Support/Sublime Text 3"
SRCTREE_ROOT="${HOME}/Library/Application Support/SourceTree"
BACKUP_ROOT="/Volumes/software"

# Inline Brewfile so that we can pipe this script direct to shell.
cat > ${TEMPDIR}/Brewfile <<BREWFILE
cask_args appdir: '/Applications'
tap 'caskroom/cask'
# Brew packages
brew 'fish'
brew 'go'
brew 'mongodb', restart_service: :changed
brew 'p7zip'
brew 'nodejs', args: ['with-npm']
brew 'gdrive'
brew 'mas'
# Cask packages
# cask 'font-consolas-for-powerline'
# cask 'font-inconsolata-dz-for-powerline'
# cask 'font-ubuntu-mono-powerline'
cask 'git'
cask 'google-drive'
cask 'google-chrome'
cask 'iterm2'
cask 'dropbox'
cask 'sublime-text'
cask '1password'
cask 'spectacle'
cask 'keepassx'
cask 'sourcetree'
cask 'the-unarchiver'
cask 'plex-home-theater'
cask 'soulver'
cask 'steam'
# mas packages
mas 'Wunderlist', id: 410628904
BREWFILE

# Find a file using gdrive
function find_gdrive() {
  gdrive list --no-header -m 1 --query "name=\"${1}\"" --order 'modifiedTime desc' | awk '{print $1}'
}

# Setup homebrew and cask packages.
function homebrew_setup() {
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Setting up Homebrew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null > ${LOGFILE} 2>&1
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Updating Homebrew"
  brew update >> ${LOGFILE} 2>&1
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Validating Homebrew"
  brew doctor >> ${LOGFILE} 2>&1
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Install Homebrew packages"
  brew bundle --file="${TEMPDIR}/Brewfile" >> ${LOGFILE} 2>&1
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Running Homebrew cleanup"
  brew cask cleanup >> ${LOGFILE} 2>&1
  brew cleanup >> ${LOGFILE} 2>&1
}

# Restore Preferences
function restore_prefs() {
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Restoring Preferences"
  # Copy ssh keys.
  cp -na "${BACKUP_ROOT}/keys/" "${HOME}/.ssh/"
  # Clone prefs repo.
  mkdir -p ${HOME}/bin
  if [[ ! -d "${HOME}/.dotfiles" ]];then
    ssh-agent bash -c "ssh-add ${HOME}/.ssh/id_github; git clone ${DOTFILESREPO} ${HOME}/.dotfiles"
  fi
  # fish config
  FISHCFG="${HOME}/.config/fish/config.fish"
  if [[ ! -e "{$FISHCFG}" ]];then
    ln -sf "${HOME}/.dotfiles/config/config.fish" "${HOME}/.config/fish/config.fish"
  fi
  # sublime text packages
  mkdir -p "${SUBLIME_PREF_ROOT}/Packages/User"
  cp -na "${HOME}/.dotfiles/prefs/sublime/Preferences.sublime-settings" "${SUBLIME_PREF_ROOT}/Packages/User/Preferences.sublime-settings"
  cp -na "${HOME}/.dotfiles/prefs/sublime/Package Control.sublime-settings" "${SUBLIME_PREF_ROOT}/Packages/User/Package Control.sublime-settings"
  # sshconfig
  cp -na "${HOME}/.dotfiles/config/ssh.config" "${HOME}/.ssh/config"
  # sublime text license
  SUBL_LICENSE="$(find_gdrive 'License.sublime_license')"
  if [[ ! -z "${SUBL_LICENSE}" ]];then
    gdrive download --path "${SUBLIME_PREF_ROOT}/Local/" ${SUBL_LICENSE}
  fi
  # sourcetree license
  SRCTREE_LICENSE="$(find_gdrive 'sourcetree.license')"
  if [[ ! -z "${SOURCETREE_LICENSE}" ]];then
    gdrive download --path "${SRCTREE_ROOT}/" ${SRCTREE_LICENSE}
  fi
}

# Tweaks
function tweak_settings() {
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Tweaking settings"
  # Menu bar: disable transparency
  defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false
  defaults write com.apple.menuextra.battery ShowPercent -string "YES"
  defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write com.apple.LaunchServices LSQuarantine -bool false
  defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
  defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo ${HOSTNAME}
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write com.apple.screencapture location -string "$HOME/Desktop"
  defaults write com.apple.screencapture type -string "png"
  defaults write com.apple.finder QuitMenuItem -bool true
  defaults write com.apple.finder DisableAllAnimations -bool true
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
  defaults write com.apple.Finder AppleShowAllFiles -bool false
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder QLEnableTextSelection -bool true
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.frameworks.diskimages skip-verify -bool true
  defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
  defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
  defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
  defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
  defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
  defaults write com.apple.Finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder WarnOnEmptyTrash -bool false
  defaults write com.apple.dock showhidden -bool true
  # Show the ~/Library folder
  chflags nohidden ~/Library
}

function restart_services() {
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Restarting system services"
  for app in "Dock" "Finder" "SystemUIServer"; do
    killall "$app" > /dev/null 2>&1
  done
}

##################
echo [$(date +"%d-%b-%y %H:%M:%S")] "Bootstrapping OS X"

# Mount the local NAS backup share.
mount | grep -q shelby/software
if [[ "$?" -ne 0 ]];then
  osascript -e 'mount volume "cifs://shelby/software"'
fi
mount | grep -q shelby/software
if [[ "$?" -ne 0 ]];then
  echo [$(date +"%d-%b-%y %H:%M:%S")] "Failed to mount backup share, aborting ..." 
fi

# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install dependencies and basic tools using homebrew first.
homebrew_setup

# Ensure that we have an auth token for gdrive.
gdrive about
gdrive about | grep  -q "User: .*@.*";
if [[ $? -ne 0 ]];then
  # Should never reach here, since the previous gdrive input prompt
  # is blocking.
  echo "No auth token found."
  exit 1
fi

restore_prefs
tweak_settings
restart_services

rm -Rf ${TEMPDIR}
