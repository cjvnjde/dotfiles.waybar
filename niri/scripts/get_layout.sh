#!/bin/sh

layout=$(niri msg keyboard-layouts | awk '/\* / {print $3}')

echo "$layout"
