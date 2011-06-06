/* sshconf.vala
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
    class Overview : Gtk.Dialog
    {
        private string source_filename = null;
        
        private Gtk.Widget apply_button;
        private Gtk.Widget add_rule_button;
        private Gtk.Widget remove_rule_button;
        private Gtk.TreeView tree;
        private Gtk.TreeModel model;

        ~Overview()
        {
            stdout.printf("~Overview\n");
        }

        /**
         * Loading file
         */
        public async void load_file(string filename)
        {
            this.source_filename = filename;
            
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
                                (model as EntryModel).add_entry(current);/*insert_with_values(null,  
                                        i,
                                        0, current,
                                        -1);*/
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


        public void write_file()
        {
            stdout.printf("write file: %s\n", this.source_filename);
            File file = GLib.File.new_for_path(this.source_filename);
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
            model = new EntryModel();//Gtk.ListStore(1,typeof(GLib.Object));

            /* Treeview */
            var sw = new Gtk.ScrolledWindow(null,null);
            sw.shadow_type = Gtk.ShadowType.ETCHED_IN;
            tree = new Gtk.TreeView();
            tree.set_model(model);
            tree.rules_hint = true;
            sw.add(tree);
            box.pack_start(sw, true, true, 0);

            var column = new Gtk.TreeViewColumn();
            tree.append_column(column);
            var renderer = new Gtk.CellRendererText();

            column.pack_start(renderer, true);
            column.set_attributes(renderer, "text", EntryModel.Columns.NAME);
            
            renderer = new Gtk.CellRendererText();
            renderer.set("foreground", "grey");
            renderer.set("xalign", 1.0);
            
            column.pack_start(renderer, false);
            column.set_attributes(renderer, "text", EntryModel.Columns.HOSTNAME);
            
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
                    (model as EntryModel).remove_entry(en);
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

            Gtk.TreePath path = (model as EntryModel).add_entry(e);
            tree.get_selection().select_path(path);
            new Editor(this,e); 
        }

        /**
         * Quit when dialog get closed either via escape, cancel, window close
         * or save. In case of save, write out file 
         *
         * @todo: when there are changes, ask confirmation before discarding
         */
        public override void response(int response_id)
        {

            if(response_id == -1) { 
                write_file();
            }
            Gtk.main_quit();
            this.destroy();
        }

        static int main(string[] argv)
        {

            Gtk.init(ref argv);

            /* Create GtkApplication */
            var application = new Gtk.Application(
                    "org.gmpclient.sshconf",
                    GLib.ApplicationFlags.HANDLES_OPEN); 

            try{
              application.register();
            }catch (Error err) {
              stderr.printf("Failed to register application: %s\n", err.message);
              return 1;  
            }

            /* Only allow one instance off the application to be running */
            if(application.is_remote)
            {
              application.activate();
              application = null;
              return 0;
            }
            
            /* Create the gui */
            var a = new SSHConf.Overview();
            application.add_window(a);
            
            /* Create path to ~/.ssh/config */
            var path = GLib.Path.build_filename(
              GLib.Environment.get_home_dir(),
              ".ssh",
              "config");
            
            /* Load the file */
            a.load_file(path);
            
            /* Response to the activate signal on GApplication by rasing 
             * window */            
            application.activate.connect(()=>{
              (a as Gtk.Window).present();
            });

            /* Show all and run */
            a.show_all();
            Gtk.main();
            
            /* quit & cleanup */
            stdout.printf("quiting...\n");
            a = null;
            application = null;
                        
            return 0;
        }
    }
}// end SSHConf
