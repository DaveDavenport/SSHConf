/* sshconf-entry.vala
 *
 * Copyright (C) 2011 Qball Cow <qball@gmpclient.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Qball Cow <qball@gmpclient.org>
 */
using Gtk;
using Gee;
namespace SSHConf
{

    public class Entry : GLib.Object
    {
        /* Grepped from the man page */
        /* zcat /Storage/qball/Debian/usr/share/man/man5/ssh_config.5.gz |
         * grep ".It Cm" | awk  '{print "\""$3"\","}'
         * Remove host and hostname
         */
        public static string[] KEYS =
        {
            "AddressFamily",
            "BatchMode",
            "BindAddress",
            "ChallengeResponseAuthentication",
            "CheckHostIP",
            "Cipher",
            "Ciphers",
            "ClearAllForwardings",
            "Compression",
            "CompressionLevel",
            "ConnectTimeout",
            "ConnectionAttempts",
            "ControlMaster",
            "ControlPath",
            "DynamicForward",
            "EnableSSHKeysign",
            "EscapeChar",
            "ForwardAgent",
            "ForwardX11",
            "ForwardX11Trusted",
            "GSSAPIAuthentication",
            "GSSAPIDelegateCredentials",
            "GSSAPITrustDns",
            "GatewayPorts",
            "GlobalKnownHostsFile",
            "HashKnownHosts",
            "HostKeyAlgorithms",
            "HostKeyAlias",
            "HostbasedAuthentication",
            "IdentitiesOnly",
            "IdentityFile",
            "KbdInteractiveDevices",
            "LocalCommand",
            "LocalForward",
            "LogLevel",
            "MACs",
            "NoHostAuthenticationForLocalhost",
            "NumberOfPasswordPrompts",
            "PasswordAuthentication",
            "PermitLocalCommand",
            "Port",
            "PreferredAuthentications",
            "Protocol",
            "ProxyCommand",
            "PubkeyAuthentication",
            "RSAAuthentication",
            "RekeyLimit",
            "RemoteForward",
            "RhostsRSAAuthentication",
            "SendEnv",
            "ServerAliveCountMax",
            "ServerAliveInterval",
            "SetupTimeOut",
            "SmartcardDevice",
            "StrictHostKeyChecking",
            "TCPKeepAlive",
            "Tunnel",
            "TunnelDevice",
            "UsePrivilegedPort",
            "User",
            "UserKnownHostsFile",
            "VerifyHostKeyDNS",
            "XAuthLocation",
            null
        };
        
        /* Name of the entry */
        private string _name = "";
        
        public bool validate_pattern(string val)
        {
            return Regex.match_simple("^[a-zA-Z0-9\\.\\?\\*]+$", val);
        }
        public bool validate_hostname(string val)
        {
            return Regex.match_simple("^[a-zA-Z0-9\\.]*$", val);        
        }
        public string name
        {
            get
            {
                return _name;
            }
            set
            {
                if(_name != value)
                {
                    _name = value;
                    changed();
                }
            }
        }

        /* Hostname */
        private string _hostname = "";
        public string hostname
        {
            get
            {
                return _hostname;
            }
            set
            {
                if(_hostname != value)
                {
                    _hostname = value;
                    changed();
                }
            }
        }

        private bool _enabled =true;
        public bool enabled
        {
            get
            {
                return _enabled;
            }
            set
            {
                if(_enabled != value)
                {
                    _enabled = value;
                    changed();
                }
            }
        }

        public signal void changed();
        public MultiMap<string, string> settings =  new HashMultiMap<string, string>();

        public void add_pair(string key, string value)
        {
            var comp = key.down();
            stdout.printf("adding: '%s': '%s'\n", key, value);
            // Lookup the key in the KEYS list, and use that value,
            // with right capitals.
            /// @todo make a less naive implementation?
            foreach(string k in KEYS)
            {
                if(comp == k.down()) {
                    comp = k;
                    break;
                }
            }
            settings.set(comp.dup(),value.dup());
            changed();
        }
        public void update_pair(string key, string old_value, string value)
        {
            settings.remove(key, old_value);
            settings.set(key, value);
            changed();
        }
        public void remove_pair(string key, string value)
        {
            settings.remove(key, value);
            changed();
        }

        public void write_entry(GLib.DataOutputStream da) throws GLib.IOError
        {
            try
            {
                if(!_enabled) da.put_string("#");
                da.put_string("Host ");
                da.put_string(name);
                da.put_string("\n");
                if(hostname != null && hostname.length > 0)
                {
                    if(!_enabled) da.put_string("#");
                    da.put_string("\tHostname ");
                    da.put_string(hostname);
                    da.put_string("\n");
                }

                foreach(var miter in settings.get_all_keys())
                {
                    foreach(var value in settings.get(miter))
                    {
                        if(!_enabled) da.put_string("#");
                        da.put_string("\t");
                        da.put_string(miter);
                        da.put_string(" ");
                        da.put_string(value);
                        da.put_string("\n");
                    }
                }

            }
            catch (GLib.IOError er)
            {
                throw er;
            }
        }

        ~Entry()
        {
            stdout.printf("~Destroy entry\n");
        }
    }
}
