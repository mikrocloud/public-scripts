# The script is to assist ISP/WISP field technicians to configure Mikrotik routers after initial installation.
# Keep it simple, objective is to get the router online as quickly as possible with minimal user input.

# prompt for client code/name
:local input do={:put $1;:return};
:local client [$input "Enter the client code/name: "];
# set the system identity to the client code
/system identity set name=$client;
# would you like to add a new admin user? skip a line before input
:put "\n";
:local addAdminUser [$input "Would you like to add a new admin user? (yes/no)"];
:if ($addAdminUser = true ) do={
    :local username [$input "Enter the username: "];
    :local password [$input "Enter the password: "];
    # if there is a user with the same name, remove it
    :if ([:len [/user find name=$username]] > 0) do={
        /user remove $username;
    }
    /user add name=$username password=$password group=full;
    :put "User $username added";
}
:put "\n";
# prompt for connection type
:local prompt "Connection configuration: (dhcp/pppoe)?";
:local options "dhcp,pppoe,static";
# Ask for the connection type
:local input do={:put $1;:return};
:local connection [$input "Enter connection type (dhcp/pppoe/static): "];
# connection type validation
:if ([:find $options $connection] = -1) do={
    :put "Invalid connection type. Please enter dhcp, pppoe or static.";
    :put "Script execution aborted";
    :return;
}

:put "\n";;
:put "Available interfaces:";
:foreach i in=[/interface find] do={
    :put [/interface get $i name];
}
:local interface [$input "Enter the interface to use: "];
# interface validation
:if ([:typeof [/interface get $interface]] = "nil") do={
    :put "\n\n";
    :put "Invalid interface. Please enter a valid interface";
    :put "Script execution aborted";
    :return;
} else={
    :put "Interface $interface will be used for dhcp";
}

# check if they want to prepend the interface name with -wan
:put "\n";
:local prepend [$input "Would you like to rename interface with prepend -Wan? (yes/no)"];
:if ($prepend = "yes") do={
    :set interface ("$interface-Wan");
    /interface set $interface name="$interface-Wan";
    :put "Interface name will be $interface";
}
# if the selection is dhcp, add dhcp client configuration
:if ($connection = "dhcp") do={
    # remove all existing dhcp client configurations
    :foreach i in=[/ip dhcp-client find] do={
        /ip dhcp-client remove $i;
    }
    # add dhcp client configuration
    /ip dhcp-client add interface=$interface disabled=no;
}

# if the selection is pppoe, get input of which pppoe profile to use
:if ($connection = "pppoe") do={
    #list possible ppp profiles
    :put "\n";
    :put "Available ppp profiles:";
    :foreach i in=[/ppp profile find] do={
        :put [/ppp profile get $i name];
    }
    :put "\n";
    :local profile [$input "Enter the ppp profile to use: "];
    # profile validation
    :if ([:typeof [/ppp profile get $profile]] = "nil") do={
        :put "Invalid ppp profile. Please enter a valid profile";
        :put "Script execution aborted";
        :return;
    } else={
        :put "PPPoE profile $profile will be used";
    }
    # get the username and password
    :put "\n";
    :local username [$input "Enter the username: "];
    :put "\n";
    :local password [$input "Enter the password: "];
    :put "Username: $username, Password: $password will be used for PPPoE";

    # remove all existing pppoe client configurations and dhcp client configurations
    :foreach i in=[/interface pppoe-client find] do={
        /interface pppoe-client remove $i;
    }
    :foreach i in=[/ip dhcp-client find] do={
        /ip dhcp-client remove $i;
    }
    # add pppoe client configuration
    /interface pppoe-client add user=$username password=$password profile=$profile disabled=no add-default-route=yes use-peer-dns=yes interface=$interface;
    :put "PPPoE client configuration added.";
}

# if the selection is static, get input of the ip address, gateway, and dns
:if ($connection = "static") do={
    :put "\n";
    :local ip [$input "Enter the IP address (eg. 172.16.1.2/30) :"];
    :put "\n";
    :local gateway [$input "Enter the gateway (eg. 172.16.1.1) :"];
    :put "\n";
    :local dns [$input "Enter the DNS server (eg. 9.9.9.9) :"];
    :put "IP: $ip, Gateway: $gateway, DNS: $dns will be used for static configuration";
    # remove all existing dhcp client configurations
    :foreach i in=[/ip dhcp-client find] do={
        /ip dhcp-client remove $i;
    }
    # add static configuration
    /ip address add address=$ip interface=$interface;
    /ip route add gateway=$gateway;
    /ip dns set servers=$dns;
    :put "Static configuration added.";
}

# would you like to remove the default admin user?
:put "\n";
:local removeDefaultAdminUser [$input "Would you like to remove the default admin user? (yes/no)"];
:if ($removeDefaultAdminUser = "yes") do={
    # make sure another admin user exists before removing the default admin user
    :if ([:len [/user find group=admin]] > 1) do={
        /user remove admin;
    } else={
        :put "There are no other admin users. Default admin user will not be removed";
    }
}
