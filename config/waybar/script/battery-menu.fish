#!/usr/bin/env fish

set tlp_mode (tlp-stat -s | grep "Power profile" | awk '{print $4}')
set asus_mode (asusctl profile -p | grep "Active profile is" | awk '{print $4}')

set options

for opt in "Power Saving" "Balanced" "Performance"
  if test $opt = "Power Saving"
    set check_tlp "power-saver/SAV"; set check_asus "Quiet"
  else if test $opt = "Balanced"
    set check_tlp "balanced/BAT"; set check_asus "Balanced"
  else if test $opt = "Performance"
    set check_tlp "performance/AC"; set check_asus "Performance"
  end

  if test "$tlp_mode" = "$check_tlp" ; and test "$asus_mode" = "$check_asus"
    set options $options "$opt ✅"
  else
    set options $options "$opt"
  end
end

set mode_selected (printf "%s\n" $options | vicinae dmenu --placeholder "Select battery mode:")

if test -z "$mode_selected"
  exit 0
end

set mode_selected (string replace " ✅" "" $mode_selected)

switch $mode_selected
  case "Power Saving"
    sudo tlp power-saver
    sudo asusctl profile -P Quiet
  case "Balanced"
    sudo tlp balanced
    sudo asusctl profile -P Balanced
  case "Performance"
    sudo tlp performance
    sudo asusctl profile -P Performance
end
