require 'resolv'

# http://serverfault.com/questions/331936/setting-the-hostname-fqdn-or-short-name
# http://hardoop.blogspot.se/2013/02/hadoop-and-fqdn.html
# https://github.com/caskdata/hadoop_cookbook/blob/master/libraries/helpers.rb
# hostname -fqdn   is used by the tasktracker

module Kagent 
  module Helpers  
    def my_public_ip()
      node.public_ips[0]
    end

    def my_dns_name()
      node.public_ips[0]
      return dns_lookup(ip)
    end


    def my_private_ip()
      node['private_ips'][0]
    end

    def valid_cookbook(cookbook)
      if node.attribute?(cookbook) == false 
        Chef::Log.error "Invalid cookbook name: #{cookbook}"
        raise ArgumentError, "Invalid Cookbook name", cookbook
      end
    end

    def valid_recipe(cookbook, recipe)
      valid_cookbook(cookbook)
      if node[cookbook].attribute?(recipe) == false 
        Chef::Log.error "Invalid cookbook/recipe name: #{cookbook}/#{recipe}"
        raise ArgumentError, "Invalid Recipe fo cookbook #{cookbook}", recipe
      end
    end


    def public_recipe_ip(cookbook, recipe)
      valid_recipe(cookbook,recipe)
      ip = node[cookbook][recipe][:public_ips][0]
    end

    def private_recipe_ip(cookbook, recipe)
      valid_recipe(cookbook,recipe)
      ip = node[cookbook][recipe][:private_ips][0]
    end

    def private_recipe_ips(cookbook, recipe)
      valid_recipe(cookbook,recipe)
      return node[cookbook][recipe][:private_ips]
    end

    def private_recipe_hostnames(cookbook, recipe)
      valid_recipe(cookbook,recipe)
      hostf = Resolv::Hosts.new
      dns = Resolv::DNS.new

      hostnames = Array.new
      for host in node[cookbook][recipe][:private_ips]
        # resolve the hostname first in /etc/hosts, then using DNS
        # If not found, then write an entry for it in /etc/hosts
        begin
          h = hostf.getname("#{host}")
        rescue
          begin
            h = dns.getname("#{host}")
          rescue
            if (node.vagrant)
              # gsub() returns a copy of the modified str with replacements
              # gsub!() makes the replacements in-place
              # hostName = host.gsub("\.","_")
              # h = "vagrant_#{hostName}"
              # hostsfile_entry "#{host}" do
              #   hostname  "#{h}"
              #   unique    true
              #   action    :create
              # end
              h = host
              #h = "10.0.2.15"
            else 
              raise "You need to supply a valid list  of ips for #{cookbook}/#{recipe}"
            end
          end
        end
        hostnames << h 
      end
      hostnames
    end

    def set_my_hostname()
      my_ip = my_private_ip()
      my_dns_name = my_dns_name()
      hostsfile_entry "#{my_ip}" do
        hostname  node.fqdn
        unique    true
        action    :append
      end
    end

    def set_hostnames(cookbook, recipe)
      hostf = Resolv::Hosts.new
      dns = Resolv::DNS.new
      hostnames = Array.new
      for host in node[cookbook][recipe][:private_ips]
        # resolve the hostname first in /etc/hosts, then using DNS
        # If not found, then write an entry for it in /etc/hosts
        begin
          h = dns.getname("#{host}")
        rescue
          # gsub() returns a copy of the modified str with replacements, leaves original string intact.
          # Hostname should not contain '-','_', capital letters
          # http://hortonworks.com/community/forums/topic/not-able-to-start-namenode-via-ambari/
          hostName = host.gsub("\.","")
          h = "#{recipe}#{hostName}"
        end
        hostsfile_entry "#{host}" do
          hostname  "#{h}"
          action    :append
          unique    true
        end

      end

    end

    # lookup fqdn of node using  dns.
    # return ip address if dns fails after 6 seconds
    def dns_lookup ip
      Chef::Log.debug("Resolving IP #{ip}")
      fqdn = ip
      begin
        # set DNS resolution timeout to 6 seconds, otherwise it will take about 80s then throws exception when DNS server is not reachable
        fqdn = Timeout.timeout(6) { Resolv.getname(ip) }
        Chef::Log.info("Resolved IP #{ip} to FQDN #{fqdn}")
      rescue StandardError => e
        Chef::Log.warn("Unable to resolve IP #{ip} to FQDN due to #{e}")
      end
      return fqdn
    end

    # get ndb_mgmd_connectstring, or list of mysqld endpoints
    def service_endpoints(cookbook, recipe, port)
      str = ""
      for n in node[cookbook][recipe][:private_ips]
        str += n + ":" + "#{port}" + ","
      end
      str = str.chop
      str
    end
    
    def ndb_connectstring()
      connectString = ""
      for n in node['ndb']['mgmd']['private_ips']
        connectString += "#{n}:#{node['ndb']['mgmd']['port']},"
      end
      # Remove the last ','
      connectString = connectString.chop
      node.normal['ndb']['connectstring'] = connectString
    end
    
    def jdbc_url()
      # The first mysqld that a NN should contact is localhost
      # On failure, contact other mysqlds. We should configure
      # the mysqlconnector to use the first localhost and only failover
      # to other mysqlds
      jdbcUrl = "localhost:#{node['ndb']['mysql_port']},"
      for n in node['ndb']['mysqld']['private_ips']
        fqdn = dns_lookup(n)
        jdbcUrl += "#{fqdn}:#{node['ndb']['mysql_port']},"
      end
      jdbcUrl = jdbcUrl.chop
      node.normal.ndb.mysql.jdbc_url = "jdbc:mysql://" + jdbcUrl + "/"
    end
  end
end

Chef::Recipe.send(:include, Kagent::Helpers)
Chef::Resource.send(:include, Kagent::Helpers)
