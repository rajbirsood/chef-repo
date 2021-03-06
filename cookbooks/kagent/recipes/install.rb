# ubuntu python-mysqldb package install only works if we first run "apt-get update; apt-get upgrade"

case node["platform_family"]
when "debian"
  bash "apt_update_install_build_tools" do
    user "root"
    code <<-EOF
   apt-get update -y 
   apt-get install build-essential -y 
   apt-get install libssl-dev -y 
   apt-get install jq -y 
 EOF
  end

# Change lograte policy
  cookbook_file '/etc/logrotate.d/rsyslog' do
    source 'rsyslog.ubuntu'
    owner 'root'
    group 'root'
    mode '0644'
  end

#  package "python-openssl" eo
#  action :install
#  end

when "rhel"
  package "epel-release" do
    action :install
  end
# gcc, gcc-c++, kernel-devel are the equivalent of "build-essential" from apt.
  package "gcc" do
    action :install
  end
  package "gcc-c++" do
    action :install
  end
  package "kernel-devel" do
    action :install
  end
  package "openssl" do
    action :install
  end
  package "openssl-devel" do
    action :install
  end
  package "openssl-libs" do
    action :install
  end
  package "python" do 
    action :install
  end
  package "python-pip" do 
    action :install
  end
  package "python-devel" do 
    action :install
  end
  package "python-lxml" do 
    action :install
  end
  package "jq" do
    action :install
  end

  # Change lograte policy
  cookbook_file '/etc/logrotate.d/syslog' do
    source 'syslog.centos'
    owner 'root'
    group 'root'
    mode '0644'
  end
end


#installs python 2
include_recipe "poise-python"
# The openssl::upgrade recipe doesn't install openssl-dev/libssl-dev, needed by python-ssl
# Now using packages in ubuntu/centos.
#include_recipe "openssl::upgrade"

group node["kagent"]["group"] do
  action :create
  not_if "getent group #{node["kagent"]["group"]}"
end

group node["kagent"]["certs_group"] do
  action :create
  not_if "getent group #{node["kagent"]["certs_group"]}"
end

user node["kagent"]["user"] do
  gid node["kagent"]["group"]
  manage_home true
  home "/home/#{node["kagent"]["user"]}"
  action :create
  system true
  shell "/bin/bash"
  not_if "getent passwd #{node["kagent"]["user"]}"
end

group node["kagent"]["group"] do
  action :modify
  members ["#{node["kagent"]["user"]}"]
  append true
end

group node["kagent"]["certs_group"] do
  action :modify
  members ["#{node["kagent"]["user"]}"]
  append true
end


# ubuntu python-mysqldb package install only works if we first run "apt-get update; apt-get upgrade"
if platform?("ubuntu", "debian") 
  package "python-mysqldb" do
   options "--force-yes"
   action :install
  end
elsif platform?("centos","redhat","fedora")
  package "MySQL-python" do
    action :install
  end
else
  python_package "MySQL-python" do
    action :install
  end
end

bash "install_python" do
  user 'root'
  ignore_failure true
  code <<-EOF
  pip install --upgrade inifile
  pip install --upgrade requests
  pip install --upgrade bottle
  pip install --upgrade CherryPy
  pip install --upgrade pyOpenSSL
  pip install --upgrade netifaces
  pip install --upgrade IPy
  pip install --upgrade pexpect
  # sudo -H pip install --upgrade cherrypy-wsgiserver
  pip install --upgrade wsgiserver
 EOF
end



# bottle="bottle-0.11.4"
# cookbook_file "/tmp/#{bottle}.tar.gz" do
#   source "#{bottle}.tar.gz"
#   owner node["kagent"]["user"]
#   group node["kagent"]["user"]
#   mode 0755
#   action :create_if_missing
# end

# cherry="CherryPy-3.2.2"
# cookbook_file "/tmp/#{cherry}.tar.gz" do
#   source "#{cherry}.tar.gz"
#   owner node["kagent"]["user"]
#   group node["kagent"]["user"]
#   mode 0755
# end


# bash "install_python" do
#   user "root"
#   code <<-EOF
#   cd /tmp
#   tar zxf "#{bottle}.tar.gz"
#   cd #{bottle}
#   python setup.py install
#   cd ..
#   tar zxf "#{cherry}.tar.gz"
#   cd #{cherry}
#   python setup.py install
#   cd ..
#  EOF
#   not_if "python -m wsgiserver"
# end


# ubuntu python-mysqldb package install only works if we first run "apt-get update; apt-get upgrade"
if platform?("ubuntu", "debian") 
  package "python-mysqldb" do
   options "--force-yes"
   action :install
  end
elsif platform?("centos","redhat","fedora")
  package "MySQL-python" do
    action :install
  end
else
  python_package "MySQL-python" do
    action :install
  end
end

bash "make_gemrc_file" do
  user "root"
  code <<-EOF
   echo "gem: --no-ri --no-rdoc" > ~/.gemrc
 EOF
  not_if "test -f ~/.python_libs_installed"
end

chef_gem "inifile" do
  action :install
end  

directory node["kagent"]["dir"]  do
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  mode "755"
  action :create
  not_if { File.directory?("#{node["kagent"]["dir"]}") }
end

directory node["kagent"]["home"] do
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  mode "750"
  action :create
end

directory node["kagent"]["certs_dir"] do
  owner node["kagent"]["user"]
  group node["kagent"]["certs_group"]
  mode "750"
  action :create
end


link node["kagent"]["base_dir"] do
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  to node["kagent"]["home"]
end

directory "#{node["kagent"]["base_dir"]}/bin" do
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  mode "755"
  action :create
end

directory node["kagent"]["keystore_dir"] do
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  mode "750"
  action :create
end

file node["kagent"]["services"] do
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  mode "755"
  action :create_if_missing
end

if node["ntp"]["install"] == "true"
  include_recipe "ntp::default"
end

#require 'resolv'
#my_hostname = Resolv.getname my_private_ip()

my_hostname = node['hostname']
if node["kagent"].attribute?("hostname") then
 my_hostname = node["kagent"]["hostname"]
end

template "#{node["kagent"]["base_dir"]}/agent.py" do
  source "agent.py.erb"
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  mode 0710
  variables({
              :kstore => "#{node["kagent"]["keystore_dir"]}/#{my_hostname}__kstore.jks",
              :tstore => "#{node["kagent"]["keystore_dir"]}/#{my_hostname}__tstore.jks"
            })
end


template"#{node["kagent"]["certs_dir"]}/csr.py" do
  source "csr.py.erb"
  owner node["kagent"]["user"]
  group node["kagent"]["certs_group"]
  mode 0710
  variables({
              :kstore => "#{node["kagent"]["keystore_dir"]}/#{my_hostname}__kstore.jks",
              :tstore => "#{node["kagent"]["keystore_dir"]}/#{my_hostname}__tstore.jks"
            })
end


['start-agent.sh', 'stop-agent.sh', 'restart-agent.sh', 'get-pid.sh'].each do |script|
  Chef::Log.info "Installing #{script}"
  template "#{node["kagent"]["base_dir"]}/bin/#{script}" do
    source "#{script}.erb"
    owner node["kagent"]["user"]
    group node["kagent"]["group"]
    mode 0750
  end
end 

['services'].each do |conf|
  Chef::Log.info "Installing #{conf}"
  template "#{node["kagent"]["base_dir"]}/#{conf}" do
    source "#{conf}.erb"
    owner node["kagent"]["user"]
    group node["kagent"]["group"]
    mode 0644
  end
end

['start-service.sh', 'stop-service.sh', 'restart-service.sh', 'status-service.sh'].each do |script|
  template  "#{node["kagent"]["base_dir"]}/bin/#{script}" do
    source "#{script}.erb"
    owner "root"
    group node["kagent"]["group"]
    mode 0750
  end
end


# set_my_hostname
if node["vagrant"] === "true" || node["vagrant"] == true 
    node[:kagent][:default][:private_ips].each_with_index do |ip, index| 
      hostsfile_entry "#{ip}" do
        hostname  "hopsworks#{index}"
        action    :create
        unique    true
      end
    end
end

jupyter_python = "true"
if node.attribute?("jupyter") 
  if node["jupyter"].attribute?("python") 
    jupyter_python = "#{node['jupyter']['python']}".downcase
  end
end

hadoop_version = "2.7.3"
if node.attribute?("hops") 
  if node["hops"].attribute?("version") 
    hadoop_version = node['hops']['version']
  end
end


template "#{node["kagent"]["home"]}/bin/conda.sh" do
  source "conda.sh.erb"
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  mode "755"
  action :create
end

template "#{node["kagent"]["home"]}/bin/anaconda_env.sh" do
  source "anaconda_env.sh.erb"
  owner node["kagent"]["user"]
  group node["kagent"]["group"]
  mode "755"
  action :create
  variables({
        :jupyter_python => jupyter_python,
        :hadoop_version => hadoop_version
  })
end


template "/etc/sudoers.d/kagent" do
  source "sudoers.erb"
  owner "root"
  group "root"
  mode "0440"
  variables({
                :user => node["kagent"]["user"],
                :conda =>  "#{node["kagent"]["base_dir"]}/bin/conda.sh",
                :anaconda =>  "#{node["kagent"]["base_dir"]}/bin/anaconda_env.sh",
                :start => "#{node["kagent"]["base_dir"]}/bin/start-service.sh",
                :stop => "#{node["kagent"]["base_dir"]}/bin/stop-service.sh",
                :restart => "#{node["kagent"]["base_dir"]}/bin/restart-service.sh",
                :status => "#{node["kagent"]["base_dir"]}/bin/status-service.sh",
                :startall => "#{node["kagent"]["base_dir"]}/bin/start-all-local-services.sh",
                :stopall => "#{node["kagent"]["base_dir"]}/bin/shutdown-all-local-services.sh",
                :statusall => "#{node["kagent"]["base_dir"]}/bin/status-all-local-services.sh"                
              })
  action :create
end  


# case node[:platform_family]
# when "rhel"
#      package "pyOpenSSL" do
#       action :install
#      end
#      package "python-netifaces" do
#       action :install
#      end

# when "debian"
#      package "python-openssl" do
#       action :install
#      end
# end

#include_recipe "kagent::anaconda"
