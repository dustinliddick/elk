#!/bin/bash


# This script configures the node as a redis broker sending to logstash on backend processors

set -e
# Setup logging
# Logs stderr and stdout to separate files.
mkdir /opt/collegis/software/logstash java elasticsearch kibana redis
exec 2> >(tee "/opt/collegis/software/logstash/install_Logstash-ELK-ES-Cluster-broker-node.err")
exec 1> >(tee "/opt/collegis/software/logstash/install_Logstash-ELK-ES-Cluster-broker-node.log")

# Setting colors for output
red="$(tput setaf 1)"
yellow="$(tput bold ; tput setaf 3)"
NC="$(tput sgr0)"

# Capture your FQDN Domain Name and IP Address
echo "${yellow}Capturing your hostname${NC}"
yourhostname=$(hostname)
echo "${yellow}Capturing your domain name${NC}"
yourdomainname=$(dnsdomainname)
echo "${yellow}Capturing your FQDN${NC}"
yourfqdn=$(hostname -f)
echo "${yellow}Detecting IP Address${NC}"
IPADDY="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
echo "Your hostname is currently ${red}$yourhostname${NC}"
echo "Your domain name is currently ${red}$yourdomainname${NC}"
echo "Your FQDN is currently ${red}$yourfqdn${NC}"
echo "Detected IP Address is ${red}$IPADDY${NC}"
sleep 10

##################### Logstash Front-End Broker Setup ###########################################

# Install Logstash
yum install --nogpgcheck -y logstash

# Enable logstash start on bootup
chkconfig logstash on

# Create Logstash configuration file
tee -a /etc/logstash/conf.d/logstash.conf <<EOF
input {
        tcp {
                type => "syslog"
                port => "5544"
        }
}
input {
        tcp {
                type => "firewall"
                port => "5545"
        }
}
input {
        tcp {
                type => "VMware"
                port => "1514"
        }
}
input {
        tcp {
                type => "vCenter"
                port => "1515"
        }
}
input {
        tcp {
                type => "Netscaler"
                port => "1517"
        }
}
input {
        tcp {
                type => "eventlog"
                port => "3515"
                format => "json"
        }
}
input {
        tcp {
                type => "iis"
                port => "3525"
                codec => "json_lines"
        }
}
output {
  redis {
  host => "elkindex-ob-1p"
  data_type => "list"
  key => "logstash"
  }
}
EOF

# Update elasticsearch-template for logstash
mv /opt/logstash/lib/logstash/outputs/elasticsearch/elasticsearch-template.json /opt/logstash/lib/logstash/outputs/elasticsearch/elasticsearch-template.json.orig
tee -a /opt/logstash/lib/logstash/outputs/elasticsearch/elasticsearch-template.json <<EOF
{
  "template" : "logstash-*",
  "settings" : {
    "index.refresh_interval" : "5s"
  },
  "mappings" : {
    "_default_" : {
       "_all" : {"enabled" : true},
       "dynamic_templates" : [ {
         "string_fields" : {
           "match" : "*",
           "match_mapping_type" : "string",
           "mapping" : {
             "type" : "string", "index" : "analyzed", "omit_norms" : true,
               "fields" : {
                 "raw" : {"type": "string", "index" : "not_analyzed", "ignore_above" : 256}
               }
           }
         }
       } ],
       "properties" : {
         "@version": { "type": "string", "index": "not_analyzed" },
         "geoip"  : {
           "type" : "object",
             "dynamic": true,
             "path": "full",
             "properties" : {
               "location" : { "type" : "geo_point" }
             }
         },
        "actconn": { "type": "long", "index": "not_analyzed" },
        "backend_queue": { "type": "long", "index": "not_analyzed" },
        "beconn": { "type": "long", "index": "not_analyzed" },
        "bytes": { "type": "long", "index": "not_analyzed" },
        "bytes_read": { "type": "long", "index": "not_analyzed" },
        "datastore_latency_from": { "type": "long", "index": "not_analyzed" },
        "datastore_latency_to": { "type": "long", "index": "not_analyzed" },
        "feconn": { "type": "long", "index": "not_analyzed" },
        "response_time": { "type": "long", "index": "not_analyzed" },
        "retries": { "type": "long", "index": "not_analyzed" },
        "srv_queue": { "type": "long", "index": "not_analyzed" },
        "srvconn": { "type": "long", "index": "not_analyzed" },
        "time_backend_connect": { "type": "long", "index": "not_analyzed" },
        "time_backend_response": { "type": "long", "index": "not_analyzed" },
        "time_duration": { "type": "long", "index": "not_analyzed" },
        "time_queue": { "type": "long", "index": "not_analyzed" },
        "time_request": { "type": "long", "index": "not_analyzed" }
       }
    }
  }
}
EOF

# Restart logstash service
service logstash restart

# Logrotate job for logstash
#tee -a /etc/logrotate.d/logstash <<EOF
#/var/log/logstash.log {
#        monthly
#        rotate 12
#        compress
#        delaycompress
#        missingok
#        notifempty
#        create 644 root root
#}
#EOF

# All Done
echo "${yellow}Installation has completed!!${NC}"
echo "${yellow}Please check logs for errors"
echo ""
echo "${yellow}CollegiseEdcuation.com${NC}"
echo "${yellow}Dustin Liddick${NC}"
echo "${yellow}Enjoy!!!${NC}"