#!/bin/sh

rm ios
cp -r darwin ios
git rm --cached ios

rm macos
cp -r darwin macos
git rm --cached macos
