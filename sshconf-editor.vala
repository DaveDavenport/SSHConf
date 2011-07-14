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
    class Editor : Gtk.VBox
    {
        private Entry entry;
        private Gtk.Entry name_entry = null;
        private Gtk.Entry hostname_entry = null;
        private Gtk.ListStore model = null;

        private Gtk.TreeView tree = null;
        private Gtk.ToolItem remove_rule_button = null;
        private Gtk.ToolItem add_rule_button = null;
        private Gtk.Switch enable_switch = null;

        private Gtk.TreeModel keys_model = null;
        private Gtk.Label title_label = null;

        private Gtk.HBox enable_hbox = null;
        private Gtk.HBox name_hbox = null;
        private Gtk.HBox hostname_hbox = null;


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

        
            title_label = new Label("");
            title_label.set_markup("<span size='xx-large' weight='bold'>Entry settings</span>");
            this.pack_start(title_label, false, false, 0);
            title_label.set_alignment(0f, 0.5f);
            title_label.set_padding(6,6);
        
        
            int i=0;

            keys_model = new Gtk.ListStore(1, typeof(string));
            for(i=0; Entry.KEYS[i] != null; i++)
            {
                (keys_model as ListStore).insert_with_values(null,i, 0, Entry.KEYS[i]);
            }

            var SizeGroup = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
            /**
             * Enable button
             */
             enable_hbox = new Gtk.HBox(false,6);
             enable_switch = new Gtk.Switch();
             var ali = new Gtk.Alignment(0.0f, 0.5f, 0.0f, 0.0f);
             ali.add(enable_switch);
             var label = new Label("Enable");
             SizeGroup.add_widget(label);
             label.set_alignment(1f, 0.5f);
             enable_hbox.pack_start(label, false, false, 0);
             enable_hbox.pack_start(ali, true, true, 0);
             this.pack_start(enable_hbox, false, false, 3);

            enable_switch.notify["active"].connect((source) => {
                stdout.printf("Switch activate toggle\n");
                entry.enabled = enable_switch.get_active();            
            });


            /* Name entry */
            name_hbox = new Gtk.HBox(false,6);
            label = new Label("Name");
            SizeGroup.add_widget(label);
            label.set_alignment(1f, 0.5f);
            name_entry = new Gtk.Entry();
            name_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-no");            
            name_entry.changed.connect((source) => {
                if((source as Gtk.Entry).get_text() != entry.name) {
                    entry.name = (source as Gtk.Entry).get_text();
                }
                if(entry.validate_pattern(entry.name)) {
                    name_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-yes");
                }else{
                    name_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-no");
                }
            });
            name_hbox.pack_start(label, false, false, 0);
            name_hbox.pack_start(name_entry, true, true, 0);
            this.pack_start(name_hbox, false, false, 3);


            /* Hostname entry */
            hostname_hbox = new Gtk.HBox(false,6);
            label = new Label("Hostname");
            SizeGroup.add_widget(label);
            label.set_alignment(1f, 0.5f);
            hostname_entry = new Gtk.Entry();
            hostname_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-yes");            
            hostname_entry.changed.connect((source) => {
                if((source as Gtk.Entry).get_text() != entry.hostname) {
                    entry.hostname = (source as Gtk.Entry).get_text();
                }
                if(entry.validate_hostname(entry.hostname)) {
                    hostname_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-yes");
                }else{
                    hostname_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-no");
                }
            });
            hostname_hbox.pack_start(label, false, false, 0);
            hostname_hbox.pack_start(hostname_entry, true, true, 0);
            this.pack_start(hostname_hbox, false, false,3);

            /* tree */
            model = new Gtk.ListStore(2, typeof(string), typeof(string));

            var sw = new Gtk.ScrolledWindow(null,null);
            sw.shadow_type = Gtk.ShadowType.ETCHED_IN;
            tree = new Gtk.TreeView();
            tree.set_model(model);
            tree.rules_hint = true;
            sw.add(tree);
            this.pack_start(sw, true, true, 0);

            var renderer = new Gtk.CellRendererCombo();
	        renderer.has_entry = true;
            tree.insert_column_with_attributes(0,"Key", renderer, "text",0,null);
            renderer.set("model", keys_model);
            renderer.set("text-column", 0);
            renderer.set("editable", true);
            tree.get_column(0).set_min_width(150);
            tree.get_column(0).set_sizing(Gtk.TreeViewColumnSizing.FIXED);


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
            var bbox = new Gtk.Toolbar();
            /**
             * Setup the styles for the button box
             */
            var context = bbox.get_style_context();
            context.set_junction_sides(Gtk.JunctionSides.TOP);
            context.add_class(Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            context = sw.get_style_context();
            context.set_junction_sides(Gtk.JunctionSides.BOTTOM);

            //bbox.set_layout(Gtk.ButtonBoxStyle.END);
            /* add */
            add_rule_button = new Gtk.ToolButton.from_stock("gtk-add");
            add_rule_button.tooltip_text = "Add parameter";
            (add_rule_button as Gtk.ToolButton).clicked.connect((source) => {
                    Gtk.TreeIter iter;
                    (model as ListStore).insert_with_values(
                        out iter, -1,
                        0, "<key>",
                        1, "<value>");
                    });

            bbox.insert(add_rule_button, 0);
            /* remove */
            remove_rule_button = new Gtk.ToolButton.from_stock("gtk-remove");
            remove_rule_button.tooltip_text = "Remove parameter";
            remove_rule_button.sensitive = false;

            (remove_rule_button as Gtk.ToolButton).clicked.connect((source) => {
                Gtk.TreeIter iter;
                if(tree.get_selection().get_selected(null, out iter))
                {
                    string key,value;
                    model.get(iter, 0, out key, 1, out value);
                    entry.remove_pair(key, value);
                }
            });

            bbox.insert(remove_rule_button, 1);
            this.pack_start(bbox, false, false, 0);

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
        }

        ~Editor()
        {
            stdout.printf("~Editor\n");
        }
        public Editor (Gtk.Window parent, Entry entry)
        {
            this.entry = entry;

            enable_switch.set_active(this.entry.enabled);
            
            name_entry.set_text(entry.name);
            this.entry.notify["name"].connect(() =>{
                    name_entry.set_text(this.entry.name);
            });

            hostname_entry.set_text(entry.hostname);
            this.entry.notify["hostname"].connect(() =>{
                    hostname_entry.set_text(this.entry.hostname);
            });

            this.entry.changed.connect(() => {
                if(this.entry.enabled != enable_switch.get_active()) {
                    enable_switch.set_active(this.entry.enabled);
                }
                fill_settings_list();
            });
            fill_settings_list();
            this.show_all();

            /**
             * If default settings modify editor a bit 
             */
            if(entry is DefaultEntry) {
                title_label.set_markup("<span size='xx-large' weight='bold'>Default settings</span>");
                stdout.printf("Default entry\n");
                
                enable_hbox.hide();
                name_hbox.hide();
                hostname_hbox.hide();
            }
        }
    }
}
