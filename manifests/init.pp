# $Id: init.pp 4848 2011-11-30 13:10:13Z uwaechte $
class ipmi ($ensure = "present",
    $ipmiuser = $IPMI_USER,
    $ipmipassword = $IPMI_PASSWORD) {
    Package {
        ensure => $ensure
    }
    case $kernel {
        "Darwin" : {
            debug("no ipmitool package for darwin")
        }
        "Linux" : {
            package {
                ["ipmitool", "openipmi"] :
            }
        }
        default : {
            package {
                "ipmitool" :
            }
        }
    }
    kernel::module {
        ["ipmi_si", "ipmi_devintf", "ipmi_watchdog", "ipmi_msghandler",
        "ipmi_poweroff"] :
            ensure => $has_ipmi ? {
                "true" => "present",
                default => "absent",
            }
    }
    if $has_ipmi == "true" {
        Exec {
            path => ["/usr/bin", "/bin", "/sbin", "/usr/sbin",
            "/usr/local/bin", "/usr/local/sbin"]
        }
        exec {
            "ipmi_set_dhcplan" :
                command => "ipmitool lan set 1 ipsrc dhcp",
                onlyif =>
                "test $(ipmitool lan print 1 |grep \"IP Address Source\" |cut -f 2 -d : |grep -c DHCP) -eq 0",
                logoutput => true,
        }
        exec {
            "ipmi_mod_username" :
                command => "ipmitool user set name 2 ${ipmiuser}",
                onlyif =>
                "test \"$(ipmitool user list |tail -1 |awk '{print \$2}')\" == \"ADMIN\"",
                logoutput => true,
        }
        exec {
            "ipmi_set_user" :
                command => 'ipmitool user set password 2 \'${ipmipassword}\'',
                refreshonly => true,
                logoutput => false,
                subscribe => Exec["ipmi_mod_username"],
        }
    }
}

