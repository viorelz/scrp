#!/bin/bash

cd ~/
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> .bash_profile
echo 'eval "$(rbenv init -)"' >> .bash_profile
echo 'unset RUBYLIB' >> .bash_profile
. .bash_profile

mkdir -p log
chmod g+w log

mkdir -p ~/.rbenv/plugins
cd ~/.rbenv/plugins
git clone https://github.com/sstephenson/ruby-build.git
rbenv rehash

