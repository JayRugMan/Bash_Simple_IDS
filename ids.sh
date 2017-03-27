#!/bin/bash
#######################################################################
#                                                                     #
# This script uses who, ps, screen -ls, resolv.conf, and dig to       #
# take a snapshot of which hostnames, IP addresses, and users         #
# are accessing the server on which this script is run.               #
#                                                                     #
# It can be run as a cron job and piped to a file to log access       #
# thoughout the day.                                                  #
#                                                                     #
# This script was developed to monitor who was accessing a lab        #
# box used by the installation team and the US support staff to       #
# monitor who was accessing it and making unauthorized modifications. #
#                                                                     #
#######################################################################
 
# gathers the networks name servers from resolv.conf
NAMESERVERS=($(awk '/nameserver/ && !/None/ {print $2}' /etc/resolv.conf ))
 
# creates an argument with who command output
WHO_IS_ON="$(who | grep -v "tty")"
 
# Gather IP addresses from whom is logged into the Server
IP_ADDRESS=($(echo "${WHO_IS_ON}" | awk -F'[():]' '{print $3}'))
 
# Gather the user name being used
USER_NAME=($(echo "${WHO_IS_ON}" | awk '{print $1}'))
 
# Gather the pts/number for PID search
PTS_FOR_PID=($(echo "${WHO_IS_ON}" | awk '{print $2}'))
 
echo -e "\n\n\tNumber of Connections: ${#IP_ADDRESS[@]}\n"
 
for i in `seq 0 $((${#IP_ADDRESS[@]} - 1))`; do
    
    # PID for each PTS is found so that it can be killed in desired
    SESSION_PID=$(ps aux | awk -v PTS="@${PTS_FOR_PID[${i}]}" '$0 ~ PTS && !/awk/ {print "PID: "$2; exit}')
    
    # digs for host-name from IP addresses using primary and secondary DNS servers in resolv.conf
    NAME_DUG=$(dig -x ${IP_ADDRESS[${i}]} @${NAMESERVERS[0]} +short 2>/dev/null ||\
        dig -x ${IP_ADDRESS[${i}]} @${NAMESERVERS[1]} +short 2>/dev/null ||\
        echo "Name Not Found") 
        
    #NS_LOOKUP_RESULT="$(nslookup ${IP_ADDRESS[${i}]};sleep 1)"
    # run twice because the first iteration occasionally comes back blank
    #nslookup ${IP_ADDRESS[${i}]} > /dev/null 2>&1
    #nslookup ${IP_ADDRESS[${i}]}| awk 'NR==5{print "Computer: "$4}'
    #echo $NS_LOOKUP_RESULT | awk '{print "Computer: "$10}'
    
    # prints connection and session information for each connection
    echo -e "\t${NAME_DUG}"
    echo "  IP address: ${IP_ADDRESS[${i}]}"
    echo "  User Name: ${USER_NAME[${i}]}"
    echo "  PTS: ${PTS_FOR_PID[${i}]}"
    echo -e "  Session ${SESSION_PID}\n"
done

# displays all PIDs with pts connections as well as all active screen sessions
echo -e "\n\n\tSession Processes:\n"
ps aux | awk '/@pts\//'
echo -e "\n\n\tScreen Sessions:\n"
screen -ls
 