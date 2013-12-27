#
#Recipe will deploy war to tomcat
#

service "tomcat" do
  service_name "tomcat#{node["tomcat"]["base_version"]}"
  case node["platform"]
  when "centos","redhat","fedora"
    supports :restart => true, :status => true
  when "debian","ubuntu"
    supports :restart => true, :reload => false, :status => true
  end
  action :nothing
end

#download and deploy war file
require 'uri'

uri = URI.parse(node['tomcat-component']['war_uri'])
file_name = File.basename(uri.path)

if ( node['tomcat-component']['lib_uri'].start_with?('http', 'ftp') )
  remote_file "/tmp/#{file_name}" do
    source node['tomcat-component']['war_uri']
  end
end


#create contex file
