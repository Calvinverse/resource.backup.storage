# frozen_string_literal: true

require 'spec_helper'

describe 'resource_backup_storage::syncthing' do
  context 'creates the syncthing user' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }
  end

  context 'installs syncthing' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates and mounts the data file system at /srv/backup' do
      expect(chef_run).to create_directory('/srv/backup')
    end

    it 'installs the syncthing apt_repository' do
      expect(chef_run).to add_apt_repository('syncthing-repository').with(
        action: [:add],
        key: 'https://syncthing.net/release-key.txt',
        uri: 'https://apt.syncthing.net/'
      )
    end

    it 'installs the syncthing package' do
      expect(chef_run).to install_apt_package('syncthing')
    end

    it 'installs the syncthing service' do
      expect(chef_run).to create_systemd_service('syncthing').with(
        action: [:create],
        after: %w[multi-user.target],
        description: 'Syncthing - Open Source Continuous File Synchronization',
        wanted_by: %w[multi-user.target],
        exec_reload: '/bin/kill -s HUP $MAINPID',
        exec_start: '/usr/bin/syncthing -no-browser -no-restart -logflags=0 -home=/etc/syncthing',
        restart: 'on-failure',
        user: 'syncthing'
      )
    end
  end

  context 'configures the firewall for Syncthing' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'opens the syncthing HTTP port' do
      expect(chef_run).to create_firewall_rule('syncthing-http').with(
        command: :allow,
        dest_port: 22_000,
        direction: :in
      )
    end

    it 'opens the syncthing discovery port' do
      expect(chef_run).to create_firewall_rule('syncthing-discovery').with(
        command: :allow,
        dest_port: 21_027,
        direction: :in
      )
    end

    it 'opens the syncthing UI port' do
      expect(chef_run).to create_firewall_rule('syncthing-ui').with(
        command: :allow,
        dest_port: 8384,
        direction: :in
      )
    end
  end

  context 'registers the service with consul' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    consul_syncthing_http_config_content = <<~JSON
      {
        "services": [
          {
            "checks": [
              {
                "header": { "X-API-Key" : ["1234565"]},
                "http": "http://localhost:8384/rest/system/ping",
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
            "port": 22000,
            "tags": [
              "http"
            ]
          }
        ]
      }
    JSON
    it 'creates the /etc/consul/conf.d/syncthing-http.json' do
      expect(chef_run).to create_file('/etc/consul/conf.d/syncthing-http.json')
        .with_content(consul_syncthing_http_config_content)
    end
  end

  context 'adds the consul-template files for telegraf monitoring of influxdb' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }
  end
end
