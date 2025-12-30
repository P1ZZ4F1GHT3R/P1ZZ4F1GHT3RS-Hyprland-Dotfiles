#!/bin/bash

for pkg in */; do
  stow -v "${pkg%/}"
done