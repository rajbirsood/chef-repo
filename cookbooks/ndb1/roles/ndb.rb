name "ndb"
description "ndb mysql"  
run_list "recipe[kagent::install]","recipe[ndb::install]","recipe[ndb::mgmd]","recipe[ndb::ndbd]","recipe[ndb::mysqld]","recipe[ndb::memcached]","recipe[ndb::bench]"
default_attributes( "ndb" => {
     "user" => "mysql",
      "group" => "mysql",
      "dir" => "/tmp",
     # "services" => "true",
      "DataMemory" => "111",
      "private_ips" => ["10.0.2.15"],
      "public_ips" =>  ["10.0.2.15"],
      "mysql_port" =>  "3399",
      "mysql_socket" => "/tmp/mysql-alt.sock",
        "mgmd" => {
    		   "private_ips" => ["10.0.2.15"] 
 	 },
	 "ndbd" => {
 		   "private_ips" => ["10.0.2.15"]
  	 } ,
	 "mysqld" => {
                "private_ips" => ["10.0.2.15"]
         },
	 "memcached" => {
                 "private_ips" => ["10.0.2.15"]
         },
   },
  "kagent" => {
	  "enabled" => "false",
         "private_ips" => ["10.0.2.15"],
        "public_ips" => ["10.0.2.15"]
  }, 
  "services" => {
        "enabled" => "true"
     },				    
    "private_ips" => ["10.0.2.15"],
    "public_ips" => ["10.0.2.15"],
    "vagrant" => "true"	
)
																																	    
