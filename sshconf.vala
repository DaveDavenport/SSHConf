/**
 * @todo: Fix GApplication uasge
 */
using Gtk;
using Gee;
namespace SSHConf
{
    /**
     * Entry 
     */
    public class Entry : GLib.Object 
    {
        /* Grepped from the man page */
        /* zcat /Storage/qball/Debian/usr/share/man/man5/ssh_config.5.gz | grep ".It Cm" | awk  '{print "\""$3"\","}' 
         * Remove host and hostname
         */
        public static string[] KEYS = {
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
            "ConnectionAttempts",
            "ConnectTimeout",
            "ControlMaster",
            "ControlPath",
            "DynamicForward",
            "EnableSSHKeysign",
            "EscapeChar",
            "ForwardAgent",
            "ForwardX11",
            "ForwardX11Trusted",
            "GatewayPorts",
            "GlobalKnownHostsFile",
            "GSSAPIAuthentication",
            "GSSAPIDelegateCredentials",
            "GSSAPITrustDns",
            "HashKnownHosts",
            "HostbasedAuthentication",
            "HostKeyAlgorithms",
            "HostKeyAlias",
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
            "RekeyLimit",
            "RemoteForward",
            "RhostsRSAAuthentication",
            "RSAAuthentication",
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
        public string name {
                get {
                    return _name;
                } 
                set {
                    _name = value;
                }
        }

        /* Hostname */
        private string _hostname = ""; 
        public string hostname {
                get {
                    return _hostname; 
                }
                set {
                    _hostname = value;
                }               
        }

        public signal void changed();
        public MultiMap<string, string> settings =  new HashMultiMap<string, string>();

        public void add_pair(string key, string value)
        {
            stdout.printf("adding: '%s': '%s'\n", key, value);
            settings.set(key.dup(),value.dup());
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
            try {
                da.put_string("Host ");
                da.put_string(name);
                da.put_string("\n");
                if(hostname != null && hostname.length > 0)
                {
                    da.put_string("\tHostname ");
                    da.put_string(hostname);
                    da.put_string("\n");
                }

                foreach(var miter in settings.get_all_keys())
                {
                    foreach(var value in settings.get(miter))
                    {
                        da.put_string("\t");
                        da.put_string(miter);
                        da.put_string(" ");
                        da.put_string(value);
                        da.put_string("\n");
                    }
                }

            }catch (GLib.IOError er) {
                throw er;
            }
        }


        ~Entry()
        {
            stdout.printf("~Destroy entry\n");
        }
    }

    class Overview : Gtk.Dialog
    {
        public Gtk.Widget apply_button;
        public Gtk.Widget add_rule_button;
        public Gtk.Widget remove_rule_button;
        public Gtk.TreeView tree;
        public Gtk.TreeModel model;



        ~Overview()
        {
            stdout.printf("~Overview\n");
            (model as Gtk.ListStore).clear();

        }


        private void cell_data_func(
                Gtk.TreeViewColumn column, 
                Gtk.CellRenderer renderer, 
                Gtk.TreeModel model, 
                Gtk.TreeIter iter)
        {
            unowned Entry entry;
            model.get(iter, 0, out entry);

            renderer.set("text", entry.name);
        }


        /**
         * Loading file
         */
        public async void load_file(string filename)
        {
            File file = GLib.File.new_for_path(filename);

            try {
                int i = 0;
                string? res = null;
                Entry? current = null;
                var stream = yield file.open_readwrite_async();
                var bdstream = new DataInputStream(stream.input_stream);
                do{
                    res = yield bdstream.read_line_async();
                    if(res != null) 
                    {
                        string[] cmds = res.strip().split(" ",2);
                        if(cmds.length > 0)
                        {
                            if(cmds[0].down() == "host")
                            {
                                current  = new Entry();
                                current.name = cmds[1].strip(); 
                                (model as Gtk.ListStore).insert_with_values(null,  
                                        i,
                                        0, current,
                                        -1);
                                i++;
                            }
                            else if (cmds[0].down() == "hostname")
                            {
                                if(current == null) 
                                    continue;
                                current.hostname = cmds[1].strip();
                            }
                            else
                            {
                                if(current == null) {
                                    continue; 
                                }
                                current.add_pair(cmds[0].strip(), cmds[1].strip());
                            }
                        }					
                    }
                }while(res != null);
            }catch(Error e)
            {

            }
        }


        public void write_file(string filename)
        {
            stdout.printf("write file: %s\n", filename);
            File file = GLib.File.new_for_path(filename);
            try {
                stdout.printf("write file 1\n");
                var stream = file.replace(null, true,FileCreateFlags.REPLACE_DESTINATION );
                var da = new DataOutputStream (stream);

                Gtk.TreeIter iter;
                stdout.printf("write file 2\n");
                if(model.get_iter_first(out iter))
                {
                    do{
                        Entry? en = null;
                        model.get(iter, 0, out en); 
                        en.write_entry(da);
                        da.put_string("\n");
                    }while(model.iter_next(ref iter));
                }

            }catch(Error e)
            {
                stdout.printf("failed to write file: %s\n", e.message);
            }
        }


        construct {
            /* SSH Config */
            this.set_title("SSH Config");

            this.set_size_request(400, 400);

            /* Apply button */
            apply_button = this.add_button("gtk-cancel", -2);

            /* Close button */
            this.add_button("gtk-save", -1);

            /* The internal */
            var box = new Gtk.VBox(false, 6);
            (this.get_content_area() as Gtk.Box).pack_start(box, true, true, 0);
            box.set_border_width(8);

            /* Label */
            var label = new Gtk.Label("");
            label.set_markup("<span size='xx-large'>SSH Config</span>");
            label.set_alignment(0.0f, 0.5f);
            box.pack_start(label, false, false, 0);


            /* Model */
            model = new Gtk.ListStore(1,typeof(GLib.Object));

            /* Treeview */
            var sw = new Gtk.ScrolledWindow(null,null);
            sw.shadow_type = Gtk.ShadowType.ETCHED_IN;
            tree = new Gtk.TreeView();
            tree.set_model(model);
            tree.rules_hint = true;
            sw.add(tree);
            box.pack_start(sw, true, true, 0);

            var renderer = new Gtk.CellRendererText();
            tree.insert_column_with_data_func(0,"Rules", renderer, cell_data_func);

            tree.row_activated.connect((source, path, column) => {
                Gtk.TreeIter iter;
                if(source.get_model().get_iter(out iter, path))
                {
                    Entry? en = null;
                    source.get_model().get(iter, 0, out en);
                    if(en != null)
                    {
                        new Editor(this, en);
                    }
                }
            });

            /* button box */
            var hbox = new Gtk.HBox(false, 6);
            /* add */
            add_rule_button = new Gtk.Button.from_stock("gtk-add");
            (add_rule_button as Gtk.Button).clicked.connect(add_entry);
            hbox.pack_end(add_rule_button, false, false, 0);
            /* remove */
            remove_rule_button = new Gtk.Button.from_stock("gtk-remove");
            remove_rule_button.sensitive = false;
            hbox.pack_end(remove_rule_button, false, false, 0);

            (remove_rule_button as Gtk.Button).clicked.connect((source) => {
                Gtk.TreeIter iter;
                if(tree.get_selection().get_selected(null, out iter))
                {
                    Entry? en = null;
                    model.get(iter, 0, out en);
                    (model as Gtk.ListStore).remove(iter);
                    en = null;
                }
            });

            /* selection */
            tree.get_selection().changed.connect((source) => {
                Gtk.TreeIter iter;
                if(tree.get_selection().get_selected(null, out iter))
                {
                    remove_rule_button.sensitive = true;
                } else {
                    remove_rule_button.sensitive = false;
                }

            });


            box.pack_start(hbox, false, false, 0);
        }

        private void add_entry()
        {
            Entry e = new Entry();
            e.name = "New entry";
            (model as Gtk.ListStore).insert_with_values(null,  
                    0,
                    0, e,
                    -1);
        }

        public override void response(int response_id)
        {

            if(response_id == -1) { 
                write_file("/home/qball/.ssh/config");
            }
            Gtk.main_quit();
        }

        static int main(string[] argv)
        {

            Gtk.init(ref argv);

            var application = new Gtk.Application(
                    "org.gmpclient.sshconf",GLib.ApplicationFlags.HANDLES_OPEN); 

            var a = new SSHConf.Overview();
            a.load_file("/home/qball/.ssh/config");
            application.add_window(a);

            a.show_all();
            Gtk.main();
            stdout.printf("quiting...\n");


            a = null;
            return 1;
        }
    }
}// end SSHConf
