# This is the version to paste in the terminal of the Mikrotik router
# The script is to assist ISP/WISP field technicians to configure Mikrotik routers after initial installation.
# Keep it simple, objective is to get the router online as quickly as possible with minimal user input.

/system script remove ISP-Quick-Setup;
/system script add name=ISP-Quick-Setup source=":local input do={:put \$1;:return};\r\
:local client [\$input \"Enter the client code/name: \"];\r\
/system identity set name=\$client;\r\
:put \"\\n\";\r\
:local addAdminUser [\$input \"Would you like to add a new admin user? (yes/no)\"];\r\
:if (\$addAdminUser = true ) do={\r\
    :local username [\$input \"Enter the username: \"];\r\
    :local password [\$input \"Enter the password: \"];\r\
    :if ([:len [/user find name=\$username]] > 0) do={\r\
        /user remove \$username;\r\
    }\r\
    /user add name=\$username password=\$password group=full;\r\
    :put \"User \$username added\";\r\
}\r\
:put \"\\n\";\r\
:local prompt \"Connection configuration: (dhcp/pppoe)?\";\r\
:local options \"dhcp,pppoe,static\";\r\
:local input do={:put \$1;:return};\r\
:local connection [\$input \"Enter connection type (dhcp/pppoe/static): \"];\r\
:if ([:find \$options \$connection] = -1) do={\r\
    :put \"Invalid connection type. Please enter dhcp, pppoe or static.\";\r\
    :put \"Script execution aborted\";\r\
    :return;\r\
}\r\
:put \"\\n\";;\r\
:put \"Available interfaces:\";\r\
:foreach i in=[/interface find] do={\r\
    :put [/interface get \$i name];\r\
}\r\
:local interface [\$input \"Enter the interface to use: \"];\r\
:if ([:typeof [/interface get \$interface]] = \"nil\") do={\r\
    :put \"\\n\\n\";\r\
    :put \"Invalid interface. Please enter a valid interface\";\r\
    :put \"Script execution aborted\";\r\
    :return;\r\
} else={\r\
    :put \"Interface \$interface will be used for dhcp\";\r\
}\r\
:put \"\\n\";\r\
:local prepend [\$input \"Would you like to rename interface with prepend -Wan? (yes/no)\"];\r\
:if (\$prepend = \"yes\") do={\r\
    :set interface (\"\$interface-Wan\");\r\
    /interface set \$interface name=\"\$interface-Wan\";\r\
    :put \"Interface name will be \$interface\";\r\
}\r\
:if (\$connection = \"dhcp\") do={\r\
    :foreach i in=[/ip dhcp-client find] do={\r\
        /ip dhcp-client remove \$i;\r\
    }\r\
    /ip dhcp-client add interface=\$interface disabled=no;\r\
}\r\
:if (\$connection = \"pppoe\") do={\r\
    :put \"\\n\";\r\
    :put \"Available ppp profiles:\";\r\
    :foreach i in=[/ppp profile find] do={\r\
        :put [/ppp profile get \$i name];\r\
    }\r\
    :put \"\\n\";\r\
    :local profile [\$input \"Enter the ppp profile to use: \"];\r\
    :if ([:typeof [/ppp profile get \$profile]] = \"nil\") do={\r\
        :put \"Invalid ppp profile. Please enter a valid profile\";\r\
        :put \"Script execution aborted\";\r\
        :return;\r\
    } else={\r\
        :put \"PPPoE profile \$profile will be used\";\r\
    }\r\
    :put \"\\n\";\r\
    :local username [\$input \"Enter the username: \"];\r\
    :put \"\\n\";\r\
    :local password [\$input \"Enter the password: \"];\r\
    :put \"Username: \$username, Password: \$password will be used for PPPoE\";\r\
    :foreach i in=[/interface pppoe-client find] do={\r\
        /interface pppoe-client remove \$i;\r\
    }\r\
    :foreach i in=[/ip dhcp-client find] do={\r\
        /ip dhcp-client remove \$i;\r\
    }\r\
    /interface pppoe-client add user=\$username password=\$password profile=\$profile disabled=no use-peer-dns=yes add-default-route=yes interface=\$interface;\r\
    :put \"PPPoE client configuration added.\";\r\
}\r\
:if (\$connection = \"static\") do={\r\
    :put \"\\n\";\r\
    :local ip [\$input \"Enter the IP address: (eg. 172.16.1.2/30) \"];\r\
    :put \"\\n\";\r\
    :local gateway [\$input \"Enter the gateway: (eg. 172.16.1.1) \"];\r\
    :put \"\\n\";\r\
    :local dns [\$input \"Enter the DNS server: (eg. 9.9.9.9) \"];\r\
    :put \"IP: \$ip, Gateway: \$gateway, DNS: \$dns will be used for static configuration\";\r\
    :foreach i in=[/ip dhcp-client find] do={\r\
        /ip dhcp-client remove \$i;\r\
    }\r\
    /ip address add address=\$ip interface=\$interface;\r\
    /ip route add gateway=\$gateway;\r\
    /ip dns set servers=\$dns;\r\
    :put \"Static configuration added.\";\r\
}\r\
:put \"\\n\";\r\
:local removeDefaultAdminUser [\$input \"Would you like to remove the default admin user? (yes/no)\"];\r\
:if (\$removeDefaultAdmin = \"yes\") do={\r\
    :if ([:len [/user find group=admin]] > 1) do={\r\
        /user remove admin;\r\
    } else={\r\
        :put \"There are no other admin users. Default admin user will not be removed\";\r\
    }\r\
}"
/system script run ISP-Quick-Setup;