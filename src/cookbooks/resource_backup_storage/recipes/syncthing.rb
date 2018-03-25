# frozen_string_literal: true

#
# Cookbook Name:: resource_backup_storage
# Recipe:: influxdb
#
# Copyright 2017, P. van der Velde
#

#
# CREATE THE USER
#

# Configure the service user under which consul will be run
poise_service_user node['syncthing']['service_user'] do
  group node['syncthing']['service_group']
end

#
# CREATE DATA PATH
#

backup_service_path = node['backup']['service_path']
directory backup_service_path do
  action :create
  group node['syncthing']['service_group']
  owner node['syncthing']['service_user']
  recursive true
end

#
# CONFIGURATION
#

configuration_path = node['syncthing']['path']['config']
directory configuration_path do
  action :create
  group node['syncthing']['service_group']
  owner node['syncthing']['service_user']
  recursive true
end

#
# INSTALL SYNCTHING
#

apt_repository 'syncthing-repository' do
  action :add
  components ['stable']
  distribution 'syncthing'
  key 'https://syncthing.net/release-key.txt'
  uri 'https://apt.syncthing.net/'
end

apt_package 'syncthing' do
  action :install
  version node['syncthing']['version']
end

# Generate the config and the keys
execute 'syncthing' do
  command "/usr/bin/syncthing -generate=#{configuration_path}"
  creates "#{configuration_path}/config.xml"
  action :nothing
end

#
# SERVICE
#

# Create the systemd service for consultemplate.
syncthing_template_service = 'syncthing'
systemd_service syncthing_template_service do
  action :create
  after %w[multi-user.target]
  description 'Syncthing - Open Source Continuous File Synchronization'
  documentation 'https://github.com/syncthing/syncthing'
  install do
    wanted_by %w[multi-user.target]
  end
  service do
    exec_reload '/bin/kill -s HUP $MAINPID'
    exec_start "/usr/bin/syncthing -no-browser -no-restart -logflags=0 -home=#{configuration_path}"
    kill_mode 'mixed'
    kill_signal 'SIGQUIT'
    restart 'on-failure'
    restart_force_exit_status '3,4'
    success_exit_status '3,4'
    user node['syncthing']['service_user']
  end
  requires %w[multi-user.target]
end

#
# ALLOW SYNCTHING THROUGH THE FIREWALL
#

syncthing_http_port = node['syncthing']['port']['http']
firewall_rule 'syncthing-http' do
  command :allow
  description 'Allow syncthing HTTP traffic'
  dest_port syncthing_http_port
  direction :in
end

syncthing_discovery_port = node['syncthing']['port']['discovery']
firewall_rule 'syncthing-discovery' do
  command :allow
  description 'Allow syncthing discovery traffic'
  dest_port syncthing_discovery_port
  direction :in
  protocol :udp
end

syncthing_ui_port = node['syncthing']['port']['ui']
firewall_rule 'syncthing-ui' do
  command :allow
  description 'Allow syncthing remote UI traffic'
  dest_port syncthing_ui_port
  direction :in
end

#
# CONSUL FILES
#

# This assumes the health user is called 'health' and the password is 'health'
syncthing_api_key = '1234565'
file '/etc/consul/conf.d/syncthing-http.json' do
  action :create
  content <<~JSON
    {
      "services": [
        {
          "checks": [
            {
              "header": { "X-API-Key" : ["#{syncthing_api_key}"]},
              "http": "http://localhost:#{syncthing_ui_port}/rest/system/ping",
              "id": "syncthing_health_check",
              "interval": "30s",
              "method": "POST",
              "name": "Syncthing health check",
              "timeout": "5s"
            }
          ],
          "enableTagOverride": false,
          "id": "syncthing_http",
          "name": "backup",
          "port": #{syncthing_http_port},
          "tags": [
            "http"
          ]
        }
      ]
    }
  JSON
end

#
# CONSUL-TEMPLATE FILES
#
