#
# Cookbook Name:: setup_mac
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

require 'shellwords'

passwd = node["etc"]["passwd"].dup
users = passwd.reject do |u, data|
  u =~ /^_/ || %w! daemon Guest nobody root !.include?(u)
end

if users.size > 1
  raise "Cannot determine the user (#{users})"
end

username = users.first.first
userdata = users.first.last



dmg_package 'MacVim-Kaoriya' do
  volumes_dir 'MacVim-Kaoriya'
  app 'MacVim'
  source 'https://macvim-kaoriya.googlecode.com/files/macvim-kaoriya-20131023.dmg'
  action   :install
end

dmg_package 'Google Chrome' do
  dmg_name 'googlechrome'
  source   'https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'
  action   :install
end

dmg_package "Emacs" do
  source 'http://emacsformacosx.com/emacs-builds/Emacs-24.3-universal-10.6.8.dmg'
  action :install
end

dmg_package "VirtualBox" do
  source 'http://download.virtualbox.org/virtualbox/4.3.0/VirtualBox-4.3.0-89960-OSX.dmg'
  checksum "0a6391b00d5c842c492319e5e2e213bf03bd91f4c66fde34ad874236bef9f615"
  type "pkg"
  action :install
end

{
  "http://iterm2.com/downloads/stable/iTerm2_v1_0_0.zip" => "iTerm",
  "http://cachefly.alfredapp.com/Alfred_2.0.9_214.zip" => "Alfred 2",
}.each_pair do |url, name|
  unless File.exist?("/Applications/#{name}.app")
    download_to = "#{Chef::Config[:file_cache_path]}/#{File.basename(url)}"
    remote_file download_to do
      source url
    end
    execute "unzip #{download_to} -d /Applications/"
    app_path = Shellwords.shellescape("/Applications/#{name}.app")
    execute "chown -R #{username}:staff #{app_path}"
  end
end

%w! autossh zsh git !.each do |p|
  package p do
    provider Chef::Provider::Package::Homebrew
  end
end

execute "dots/setup.sh" do
  command File.expand_path(".dots/setup.sh", userdata['dir'])
  user username
  action :nothing
end

git File.expand_path(".dots", userdata['dir']) do
  repository "git@github.com:komazarari/dots.git"
  notifies :run, "execute[dots/setup.sh]"
  user username
end

