name "ndb"
description "ndb mysql"  
#run_list "recipe[kagent::install]","recipe[ndb::install]","recipe[ndb::mgmd]","recipe[ndb::ndbd]","recipe[ndb::mysqld]","recipe[ndb::memcached]","recipe[ndb::bench]"
run_list "recipe[ndb::install]","recipe[ndb::mgmd]","recipe[ndb::ndbd]","recipe[ndb::mysqld]","recipe[ndb::memcached]","recipe[ndb::bench]"
default_attributes( "ndb" => {
     "user" => "mysql",
      "group" => "mysql",
      "dir" => "/tmp",
     # "services" => "true",
      "DataMemory" => "111",
      "private_ips" => ["10.0.1.124"],
      "public_ips" =>  ["10.0.1.124"],
      "mysql_port" =>  "3399",
      "mysql_socket" => "/tmp/mysql-alt.sock",
      "mysql_ip" => ["10.0.1.124"],
       "ip" => ["10.0.1.124"],
        "mgmd" => {
    		   "private_ips" => ["10.0.1.124"] 
 	 },
	 "ndbd" => {
 		   "private_ips" => ["10.0.1.124"]
  	 } ,
	 "mysqld" => {
                "private_ips" => ["10.0.1.124"]
         },
	 "memcached" => {
                 "private_ips" => ["10.0.1.124"]
         }
   },
  "kagent" => {
	 "enabled" => "true",
         "private_ips" => ["10.0.1.124"],
        "public_ips" => ["10.0.1.124"]
  }, 
  "services" => {
        "enabled" => "true"
     },				    
    "private_ips" => ["10.0.1.124"],
    "public_ips" => ["10.0.1.124"],
    "vagrant" => "true"	
)
																																	    
