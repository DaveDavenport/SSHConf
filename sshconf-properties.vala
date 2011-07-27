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
    /* Possible property values */
    /* Type of property */
    public enum PropertyType
    {
        BOOL,
        INT,
        STRING,
        FILENAME,
        LOCAL_FORWARD,
        DYNAMIC_FORWARD
    }
    [Compact]
        [Immutable]
        public struct EntryProperty
    {
        /* Name of the option */
        public string       name;
        /* Type */
        public PropertyType type;
        /* Has default */
        public bool has_default;
        /* Default value (string always works) */
        public string default_value;
        /* if we can have 1 or more entries of this */
        public bool multi_instances;
    }
    /*
     * This list is gotten from ssh_config
     */
    public const EntryProperty[] KEYS =
    {
        // any inet4 ,inet6
        {
            "AddressFamily",
            PropertyType.STRING,
            false,  null,
            false
        },
        {
            "BatchMode",
            PropertyType.BOOL,
            true,   VALUE_NO,
            false
        },
        {
            "BindAddress",
            PropertyType.STRING,
            false,  null,
            false
        },
        {
            "ChallengeResponseAuthentication",
            PropertyType.BOOL,
            true,   VALUE_YES,
            false
        },
        {
            "CheckHostIP",
            PropertyType.BOOL,
            true,   VALUE_YES,
            false
        },
        // des, 3des, blowfish
        {
            "Cipher",
            PropertyType.STRING,
            true,  "3des",
            false
        },
        // this is a list.
        {
            "Ciphers",
            PropertyType.STRING,
            false, null,
            false
        },
        {
            "ClearAllForwardings",
            PropertyType.BOOL,
            true,   VALUE_NO,
            false
        },
        {
            "Compression",
            PropertyType.BOOL,
            true,   VALUE_NO,
            false
        },
        {
            "CompressionLevel",
            PropertyType.INT,
            false,  null,
            false
        },
        {
            "ConnectTimeout",
            PropertyType.INT,
            false,  null,
            false
        },
        {
            "ForwardX11",
            PropertyType.BOOL,
            true,   VALUE_NO,
            false
        },
        {
            "User",
            PropertyType.STRING,
            false,  null,
            false
        },
        {
            "IdentityFile",
            PropertyType.FILENAME,
            false,  null,
            true
        },
        {
            "Port",
            PropertyType.INT,
            false,  null,
            false
        },
        {
            "ProxyCommand",
            PropertyType.STRING,
            false,  null,
            false
        },
        {
            "LocalForward",
            PropertyType.LOCAL_FORWARD,
            false,  null,
            true
        },
        {
            "ConnectionAttempts",
            PropertyType.INT,
            true, "1",
            false
        },
        // this one needs the option yes,no,ask.
        {
            "ControlMaster",
            PropertyType.BOOL,
            true, VALUE_NO,
            false
        },
        {
            "ControlPath",
            PropertyType.STRING,
            true, "none",
            false
        },
        {
            "DynamicForward",
            PropertyType.STRING,
            false, null,
            true
        },
        {
            "EnableSSHKeysign",
            PropertyType.BOOL,
            true, VALUE_NO,
            false
        },
        {
            "EscapeChar",
            PropertyType.STRING,
            true, "~",
            false
        },
        {
            "ForwardAgent",
            PropertyType.BOOL,
            true, VALUE_NO,
            false
        },
        {
            "ForwardX11Trusted",
            PropertyType.BOOL,
            true, VALUE_YES,
            false
        },
        {
            "GSSAPIAuthentication",
            PropertyType.BOOL,
            true, VALUE_NO,
            false
        },
        {
            "GSSAPIDelegateCredentials",
            PropertyType.BOOL,
            true, VALUE_NO,
            false
        },
        {
            "GSSAPITrustDns",
            PropertyType.BOOL,
            true, VALUE_NO,
            false
        },
        {
            "GatewayPorts",
            PropertyType.BOOL,
            true, VALUE_NO,
            false
        },
        {
            "GlobalKnownHostsFile",
            PropertyType.FILENAME,
            false, null,
            false
        }
        /*
                    "HashKnownHosts",
                    "HostKeyAlgorithms",
                    "HostKeyAlias",
                    "HostbasedAuthentication",
                    "IdentitiesOnly",
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
                    "UsePrivilegedPort",*/
        /*            "UserKnownHostsFile",
                    "VerifyHostKeyDNS",
                    "XAuthLocation",*/
    };

}

