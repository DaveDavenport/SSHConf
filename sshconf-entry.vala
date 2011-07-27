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
public const string VALUE_YES = "yes";
public const string VALUE_NO = "no";
public class DefaultEntry : Entry
{
        public override void write_entry(GLib.DataOutputStream da) throws GLib.IOError
        {
            try
            {
                foreach(var prop in settings)
                {
                    unowned string value = prop.get_as_string();

                    // do not write out values without a name
                    if(value != null && value.length > 0)
                    {
                        da.put_string(prop.ep.name);
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

}

/* Class representing a property */
public class Property : GLib.Object
{
        public unowned Entry entry;
        /* The value */
        private string value =null;

        public EntryProperty? ep = null;

        ~Property()
        {
            GLib.debug("~destroy property");
        }
        public Property(Entry en,string key)
        {
            this.entry = en;

            for(uint i = 0; i<SSHConf.KEYS.length; i++)
            {
                if(KEYS[i].name.down() == key.down())
                {
                    ep = KEYS[i];
                    break;
                }
            }

            if(ep == null)
            {
                GLib.error("Unknown key: %s", key);
            }

            if(ep.has_default)
            {
                value = ep.default_value;
            }
        }
        public void set_as_int(int val)
        {
            value = "%i".printf(val);
        }
        public void set_as_bool(bool val)
        {
            value = (val)?VALUE_YES:VALUE_NO;
            GLib.debug("set value: %s", value);
        }
        public void set_as_string(string? val)
        {
            value = val;
        }
        public bool get_as_bool()
        {
            if(value != null)
            {
                return value.down() == VALUE_YES.down();
            }

            return false;
        }
        public int get_as_int()
        {
            if(value != null)
            {
                return int.parse(value);
            }

            return -1;
        }
        public unowned string? get_as_string()
        {
            return value;
        }

        /**
         * get|set_path():
         *
         * Converts from and to relative path.
         * ~/ is replaced by homedir
         */
        public string? get_as_path()
        {
            if(value == null) return null;

            string homedir = GLib.Environment.get_home_dir()+"/";
            string val = value.replace("~/",homedir);

            return val;
        }

        public void set_as_path(string? val)
        {
            if(val == null)
            {
                value = null;
                return;
            }

            string homedir = GLib.Environment.get_home_dir()+"/";
            value = val.replace(homedir, "~/");
        }

        public signal void removed();
}


public class Entry : GLib.Object
{
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
                }
            }
        }



        public Entry.copy(Entry en)
        {
            name = en.name;
            hostname = en.hostname;
            enabled = en.enabled;
            foreach(var prop in en.settings)
            {
                add_pair(prop.ep.name, prop.get_as_string());
            }
        }

        public enum ChangedType
        {
            PROPERTY_ADDED
        }
        public signal void changed(ChangedType what);
        public GLib.List<SSHConf.Property> settings = null;
        /* Check if entry has a property with key */
        public bool has_prop_key(string key)
        {
            foreach(var prop in settings)
            {
                if(prop.ep.name.down() == key.down())
                {
                    return true;
                }
            }
            return false;
        }
        public void new_prop(string key)
        {
            var entry = new Property(this,key);
            settings.append((owned)entry);
            changed(ChangedType.PROPERTY_ADDED);
        }
        public void add_pair(string key, string value)
        {
            var entry = new Property(this,key);
            entry.set_as_string(value);
            settings.append((owned)entry);
            changed(ChangedType.PROPERTY_ADDED);
        }

        public void remove_prop(Property prop)
        {
            weak GLib.List<SSHConf.Property> item = settings.find(prop);

            if(item != null)
            {
                Property p =(owned)item.data;
                settings.delete_link(item);
                p.removed();
                p = null;
            }
        }

        public virtual void write_entry(GLib.DataOutputStream da) throws GLib.IOError
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

                foreach(var prop in settings)
                {
                    unowned string value = prop.get_as_string();

                    if(value != null && value.length > 0 )
                    {
                        if(!_enabled) da.put_string("#");

                        da.put_string("\t");
                        da.put_string(prop.ep.name);
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
