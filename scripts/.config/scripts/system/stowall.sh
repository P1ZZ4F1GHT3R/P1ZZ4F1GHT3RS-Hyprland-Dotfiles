#!/bin/bash

stow --adopt hypr pavucontrol.ini wallust waybar


for pkg in */; do
  stow -v "${pkg%/}"
done