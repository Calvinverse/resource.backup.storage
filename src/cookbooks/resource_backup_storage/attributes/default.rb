# frozen_string_literal: true

#
# BACKUP
#

default['backup']['service_path'] = '/srv/backup'

#
# CONSULTEMPLATE
#

default['consul_template']['config_path'] = '/etc/consul-template.d/conf'
default['consul_template']['template_path'] = '/etc/consul-template.d/templates'

#
# FIREWALL
#

# Allow communication on the loopback address (127.0.0.1 and ::1)
default['firewall']['allow_loopback'] = true

# Do not allow MOSH connections
default['firewall']['allow_mosh'] = false

# Do not allow WinRM (which wouldn't work on Linux anyway, but close the ports just to be sure)
default['firewall']['allow_winrm'] = false

# No communication via IPv6 at all
default['firewall']['ipv6_enabled'] = false

#
# SYNCTHING
#

default['syncthing']['version'] = '0.14.45'

default['syncthing']['path']['config'] = '/etc/syncthing'

default['syncthing']['port']['discovery'] = 21_027
default['syncthing']['port']['http'] = 22_000
default['syncthing']['port']['ui'] = 8384

default['syncthing']['service_group'] = 'syncthing'
default['syncthing']['service_user'] = 'syncthing'

default['syncthing']['telegraf']['consul_template_inputs_file'] = 'telegraf_influxdb_inputs.ctmpl'

#
# TELEGRAF
#

default['telegraf']['config_directory'] = '/etc/telegraf/telegraf.d'
