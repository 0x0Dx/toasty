#!/usr/bin/env fish

argparse -n 'install.fish' -X 0 \
  'h/help' \
  'noconfirm' \
  'aur-helper=!contains -- "$_flag_value" yay paru' \
  -- $argv
or exit

if set -q _flag_h
  echo 'usage ./install.fish [-h] [--noconfirm] [--aur-helper]'
  echo
  echo 'options:'
  echo '  -h, --help                    show this help message and exit'
  echo '  --noconfirm                   do not confirm package installation'
  echo '  --aur-helper=[yay|paru]       do not confirm package installation'
  exit
end

function _out -a color text
  set_color $color
  echo $argv[3..] -- ":: $text"
  set_color normal
end

function log -a text
  _out cyan $text $argv[2..]
end

function input -a text
  _out blue $text $argv[2..]
end

function sh-read
  sh -c 'read a && echo -n "$a"' || exit 1
end

function confirm-overwrite -a path
  if test -e $path -o -L $path
    if set -q noconfirm
      input "$path already exists. Overwrite? [Y/n]"
      log 'Removing...'
      rm -rf $path
    else
      input "$path already exists. Overwrite? [Y/n]" -n
      set -l confirm (sh-read)

      if test "$noconfirm" = 'n' -o "$confirm" = 'N'
        log 'Skipping...'
        return 1
      else
        log 'Removing...'
        rm -rf $path
      end
    end
  end

  return 0
end

set -q _flag_noconfirm && set noconfirm '--noconfirm'
set -q _flag_aur_helper && set -l aur_helper $_flag_aur_helper || set -l aur_helper yay
set -q XDG_CONFIG_HOME && set -l config $XDG_CONFIG_HOME || set -l config $HOME/.config
set -q XDG_STATE_HOME && set -l state $XDG_STATE_HOME || set -l state $HOME/.local/state

set_color magenta
echo 'Toasty'
set_color normal
log 'Welcome to the Toasty dotfiles installer!'
log 'Before continuing, please ensure you have made a backup of your config directory.'

if ! set -q _flag_noconfirm
  log '[1] Two steps ahead of you!  [2] Make one for me please!'
  input '=> ' -n
  set -l choice (sh-read)

  if contains -- "$choice" 1 2
    if test $choice = 2
      log "Backing up $config..."

      if test -e $config.bak -o -L $config.bak
        input 'Backup already exists. Overwrite? [Y/n] ' -n
        set -l overwrite (sh-read)

        if test "$overwrite" = 'n' -o "$overwrite" = 'N'
          log 'Skipping...'
        else
          rm -rf $config.bak
          cp -r $config $config.bak
        end
      else
        cp -r $config $config.bak
      end
    end
  else
    log 'No choice selected. Exiting...'
    exit 1
  end
end

if ! pacman -Q $aur_helper &> /dev/null
  log "$aur_helper not installed. Installing..."

  sudo pacman -S --needed git base-devel $noconfirm
  cd /tmp
  git clone https://aur.archlinux.org/$aur_helper.git
  cd $aur_helper
  makepkg -si
  cd ..
  rm -rf $aur_helper

  if test $aur_helper = yay
    $aur_helper -Y --gendb
    $aur_helper -Y --devel --save
  else
    $aur_helper --gendb
  end
end

cd (dirname (status filename)) || exit 1

log 'Installing metapackages...'
if test $aur_helper = yay
  $aur_helper -Bi . $noconfirm
else
  $aur_helper -Ui $noconfirm
end
fish -c 'rm -f toasty-meta-*.pkg.tar.zst' 2> /dev/null
fish -c 'rm -f .SRCINFO' 2> /dev/null

if confirm-overwrite $config/hypr
  log 'Installing hypr* configs...'
  ln -s (realpath config/hypr) $config/hypr
  hyprctl reload
end

if confirm-overwrite $config/starship.toml
  log 'Installing starship configs...'
  ln -s (realpath config/starship.toml) $config/starship.toml
end
