/* sshconf-editor.vala
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
    /**
     * Edit an Entry
     */
    class Editor : Gtk.Dialog
    {
        private Entry entry;
        private Gtk.Entry name_entry = null;
        private Gtk.Entry hostname_entry = null;
        private Gtk.ListStore model = null;

        private Gtk.TreeView tree = null;
        private Gtk.Widget remove_rule_button = null;
        private Gtk.Widget add_rule_button = null;

        private Gtk.TreeModel keys_model = null;


        private void fill_settings_list()
        {
            int i = 0;
            /* Clear the list */
            model.clear();

            foreach(var key in entry.settings.get_all_keys())
            {
                foreach(var value in entry.settings.get(key))
                {
                    Gtk.TreeIter iter;
                    (model as ListStore).insert_with_values(out iter, i,
                            0, key,
                            1, value);
                   i++;
                }
            }

        }
        construct
        {
            int i=0;
            this.set_size_request(350,350);


            keys_model = new Gtk.ListStore(1, typeof(string));
            for(i=0; Entry.KEYS[i] != null; i++)
            {
                (keys_model as ListStore).insert_with_values(null,0, 0, Entry.KEYS[i]);
            }




            var vbox = new Gtk.VBox(false, 6);
            var SizeGroup = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
            /* Name entry */
            var hbox = new Gtk.HBox(false,6);
            var label = new Label("Name");
            SizeGroup.add_widget(label);
            label.set_alignment(1f, 0.5f);
            name_entry = new Gtk.Entry();
            name_entry.changed.connect((source) => {
                if((source as Gtk.Entry).get_text() != entry.name) {
                    entry.name = (source as Gtk.Entry).get_text();
                }
            });
            hbox.pack_start(label, false, false, 0);
            hbox.pack_start(name_entry, true, true, 0);
            vbox.pack_start(hbox, false, false, 0);
            /* Hostname entry */
            hbox = new Gtk.HBox(false,6);
            label = new Label("Hostname");
            SizeGroup.add_widget(label);
            label.set_alignment(1f, 0.5f);
            hostname_entry = new Gtk.Entry();
            hostname_entry.changed.connect((source) => {
                if((source as Gtk.Entry).get_text() != entry.hostname) {
                    entry.hostname = (source as Gtk.Entry).get_text();
                }
            });
            hbox.pack_start(label, false, false, 0);
            hbox.pack_start(hostname_entry, true, true, 0);
            vbox.pack_start(hbox, false, false, 0);

            (this.get_content_area() as Gtk.Box).pack_start(vbox, true, true, 0);
            vbox.border_width = 8;


            /* tree */
            model = new Gtk.ListStore(2, typeof(string), typeof(string));

            var sw = new Gtk.ScrolledWindow(null,null);
            sw.shadow_type = Gtk.ShadowType.ETCHED_IN;
            tree = new Gtk.TreeView();
            tree.set_model(model);
            tree.rules_hint = true;
            sw.add(tree);
            vbox.pack_start(sw, true, true, 0);

            var renderer = new Gtk.CellRendererCombo();
            tree.insert_column_with_attributes(0,"Key", renderer, "text",0,null);
            renderer.set("model", keys_model);
            renderer.set("text-column", 0);
            renderer.set("editable", true);
            renderer.set("has-entry", false);
            renderer.edited.connect((source, path, new_key)=> {
                Gtk.TreeIter iter;
                if(model.get_iter_from_string(out iter, path))
                {
                    string old_value, key;
                    model.get(iter, 0, out key, 1, out old_value);

                    entry.add_pair(new_key, old_value);
                    entry.remove_pair(key, old_value);
                }
            });


            var text_renderer = new Gtk.CellRendererText();
            tree.insert_column_with_attributes(1,"Value", text_renderer, "text",1, null);
            text_renderer.set("editable", true);
            text_renderer.edited.connect((source, path, new_text)=> {
                Gtk.TreeIter iter;
                if(model.get_iter_from_string(out iter, path))
                {
                    string old_value, key;
                    model.get(iter, 0, out key, 1, out old_value);

                    entry.update_pair(key, old_value, new_text);
                }
            });

            /* button box */
            hbox = new Gtk.HBox(false, 6);
            /* add */
            add_rule_button = new Gtk.Button.from_stock("gtk-add");
            (add_rule_button as Gtk.Button).clicked.connect((source) => {
                    Gtk.TreeIter iter;
                    (model as ListStore).insert_with_values(
                        out iter, -1,
                        0, "<key>",
                        1, "<value>");
                    });
            hbox.pack_end(add_rule_button, false, false, 0);
            /* remove */
            remove_rule_button = new Gtk.Button.from_stock("gtk-remove");
            remove_rule_button.sensitive = false;

            (remove_rule_button as Gtk.Button).clicked.connect((source) => {
                Gtk.TreeIter iter;
                if(tree.get_selection().get_selected(null, out iter))
                {
                    string key,value;
                    model.get(iter, 0, out key, 1, out value);
                    entry.remove_pair(key, value);
                }
            });
            hbox.pack_end(remove_rule_button, false, false, 0);
            vbox.pack_start(hbox, false, false, 0);

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

            /* Close button */
            this.add_button("gtk-close", 0);
        }
        
        public override void response (int id)
        {
            this.destroy();
        }

        ~Editor()
        {
            stdout.printf("~Editor\n");
        }
        public Editor (Gtk.Window parent, Entry entry)
        {

            this.set_transient_for(parent);
            this.entry = entry;


            name_entry.set_text(entry.name);
            this.entry.notify["name"].connect(() =>{
                    name_entry.set_text(this.entry.name);
            });

            hostname_entry.set_text(entry.hostname);
            this.entry.notify["hostname"].connect(() =>{
                    hostname_entry.set_text(this.entry.hostname);
            });

            this.entry.changed.connect(() => {
                fill_settings_list();
            });
            fill_settings_list();
            this.show_all();
        }

    }
}
