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
    class EditorProp : Gtk.HBox
    {
        protected Entry entry;
        protected Property prop;
        construct
        {
            spacing = 6;
        }
    }

    class EditorPropLocalForward : SSHConf.EditorProp
    {
        private Gtk.Entry      local_host;
        private Gtk.SpinButton local_port;
        private Gtk.Entry      remote_host;
        private Gtk.SpinButton remote_port;
        private bool block_update = false;

        public void write_to_property()
        {
            block_update = true;
            string val ="";

            if(local_host.buffer.get_length() > 0)
            {
                val += local_host.get_text();
                val += ":";
            }

            val += "%i ".printf(local_port.get_value_as_int());

            if(remote_host.buffer.get_length() > 0)
            {
                val += remote_host.get_text();
                val += ":";
            }
            val += "%i".printf(remote_port.get_value_as_int());

            prop.set_as_string(val);

            block_update = false;
        }

        public void set_from_property()
        {
            block_update = true;
            string value = prop.get_as_string();

            /* split remote local */
            var sets = value.split(" ");
            if(sets.length != 2)
            {
                GLib.warning("Wrong forward: %s", value);
                block_update = false;
                return;
            }
            /* Localhost */
            var lh = sets[0].split(":");
            if(lh.length == 1)
            {
                local_host.set_text("");
                local_port.set_value(int.parse(lh[0]));
            }
            else
            {
                local_host.set_text(lh[0]);
                local_port.set_value(int.parse(lh[1]));
            }
            /* remote */
            var rh = sets[1].split(":");
            if(rh.length == 1)
            {
                remote_host.set_text("");
                remote_port.set_value(int.parse(rh[0]));
            }
            else
            {
                remote_host.set_text(rh[0]);
                remote_port.set_value(int.parse(rh[1]));
            }

            block_update = false;
        }

        public EditorPropLocalForward(SSHConf.Entry en, Property p, Gtk.SizeGroup? sg)
        {
            entry = en;
            this.prop = p;

            this.prop.notify["value"].connect((source, spec)=>
            {
                if(!block_update)
                {
                    set_from_property();
                }
            });

            /* build gui */
            var l = new Label(prop.ep.name);
            l.set_alignment(0, 0.5f);
            pack_start(l, false, false, 0);
            if(sg!=null) sg.add_widget(l);

            // Remove button
            var remove_but = new Gtk.Button();
            remove_but.set_image(new Gtk.Image.from_stock("gtk-remove", Gtk.IconSize.MENU));
            remove_but.set_relief(Gtk.ReliefStyle.NONE);
            pack_end(remove_but, false, false, 0);
            /* remove property */
            remove_but.clicked.connect((source)=>
            {
                entry.remove_prop(this.prop);
            });

            var hbox = new Gtk.VBox(true, 6);
            pack_end(hbox,false, false,0);
            local_port = new Gtk.SpinButton.with_range(1,int.MAX, 1);
            hbox.pack_start(local_port, false, false, 0);

            remote_port = new Gtk.SpinButton.with_range(1,int.MAX,1);
            hbox.pack_start(remote_port, false, false, 0);

            hbox = new Gtk.VBox(true, 6);
            pack_end(hbox,false, false,0);
            local_host = new Gtk.Entry();
            hbox.pack_start(local_host, false, false, 0);

            remote_host = new Gtk.Entry();
            hbox.pack_start(remote_host, false, false, 0);

            /* Label */
            hbox = new Gtk.VBox(true, 6);
            pack_end(hbox,false, false,0);
            l = new Label("Local:");
            l.set_alignment(0, 0.5f);
            hbox.pack_start(l, false, false, 0);
            l = new Label("Remote:");
            l.set_alignment(0, 0.5f);
            hbox.pack_start(l, false, false, 0);

            set_from_property();

            remote_host.notify["text"].connect((source, spec)=>
            {
                if(!block_update)
                {
                    write_to_property();
                }
            });
            local_host.notify["text"].connect((source, spec)=>
            {
                if(!block_update)
                {
                    write_to_property();
                }
            });
            remote_port.notify["value"].connect((source, spec)=>
            {
                if(!block_update)
                {
                    write_to_property();
                }
            });
            local_port.notify["value"].connect((source, spec)=>
            {
                if(!block_update)
                {
                    write_to_property();
                }
            });
        }
    }
    class EditorPropGeneric : EditorProp
    {
        private Gtk.Widget field = null;
        private void setup_as_bool()
        {
            field = new Gtk.Switch();
            (field as Gtk.Switch).set_active(prop.get_as_bool());
            pack_end(field, false, false, 0);
            /* listen to property changes */
            prop.notify["value"].connect((source,spec)=>
            {
                if((field as Gtk.Switch).active != prop.get_as_bool())
                {
                    (field as Gtk.Switch).set_active(prop.get_as_bool());
                }
            });
            /* listen to switch changes */
            field.notify["active"].connect((source,spec)=>
            {
                if((field as Gtk.Switch).active != this.prop.get_as_bool())
                {
                    prop.set_as_bool((field as Gtk.Switch).active);
                }
            });
        }
        private void setup_as_int()
        {
            field = new Gtk.SpinButton.with_range(int.MIN, int.MAX, 1);

            /* set current value */
            (field as Gtk.SpinButton).set_value(prop.get_as_int());

            /* handle spin change */
            field.notify["value"].connect((source,spec)=>
            {
                int value = (source as Gtk.SpinButton).get_value_as_int();
                    if(value != prop.get_as_int())
                {
                    prop.set_as_int(value);
                }
            });
            /* listen to property changes */
            prop.notify["value"].connect((source,spec)=>
            {
                if((field as Gtk.SpinButton).get_value_as_int()
                    != prop.get_as_int())
                {
                    (field as Gtk.SpinButton).set_value(prop.get_as_int());
                }
            });
            pack_end(field, false, true, 0);
        }
        public void setup_as_string()
        {
            field = new Gtk.Entry();
            if(prop.get_as_string() != null)
            {
                (field as Gtk.Entry).set_text(prop.get_as_string());
            }
            (field as Gtk.Entry).set_width_chars(12);

            /* listen to text entry changes */
            field.notify["text"].connect((source,spec)=>
            {
                string value = (source as Gtk.Entry).get_text();
                    if(value != prop.get_as_string())
                {
                    prop.set_as_string(value);
                }
            });
            /* listen to property changes */
            prop.notify["value"].connect((source,spec)=>
            {
                if((field as Gtk.Entry).get_text()
                    != prop.get_as_string())
                {
                    (field as Gtk.Entry).set_text(prop.get_as_string());
                }
            });

            pack_end(field, false, true, 0);
        }
        public void setup_as_filename()
        {
            field = new Gtk.FileChooserButton("Select file", Gtk.FileChooserAction.OPEN);
            if(prop.get_as_string() != null)
            {
                (field as Gtk.FileChooser).set_filename(prop.get_as_path());
            }
            /* listen to property changes */
            prop.notify["value"].connect((source,spec)=>
            {
                if((field as Gtk.FileChooser).get_filename()
                    != prop.get_as_string())
                {
                    (field as Gtk.FileChooser).set_filename(prop.get_as_path());
                }
            });
            (field as Gtk.FileChooserButton).file_set.connect((source)=>
            {
                string fn = source.get_filename();
                    if(fn != prop.get_as_string())
                {
                    prop.set_as_path(fn);
                }
            });
            pack_end(field, false, true, 0);
        }
        public EditorPropGeneric(SSHConf.Entry en, Property p, Gtk.SizeGroup? sg)
        {
            entry = en;
            this.prop = p;
            var l = new Label(prop.ep.name);
            l.set_alignment(0, 0.5f);
            pack_start(l, false, false, 0);
            if(sg!=null) sg.add_widget(l);

            // Remove button
            var remove_but = new Gtk.Button();
            remove_but.set_image(new Gtk.Image.from_stock("gtk-remove", Gtk.IconSize.MENU));
            remove_but.set_relief(Gtk.ReliefStyle.NONE);
            pack_end(remove_but, false, false, 0);
            /* remove property */
            remove_but.clicked.connect((source)=>
            {
                entry.remove_prop(this.prop);
            });

            /* handle if property gets destroyed */
            prop.removed.connect(()=>
            {
                this.destroy();
            });
            /* Field (depending on type) */
            if(prop.ep.type == PropertyType.BOOL)
            {
                setup_as_bool();
            }
            else if(prop.ep.type == PropertyType.INT)
            {
                setup_as_int();
            }
            else if(prop.ep.type == PropertyType.STRING)
            {
                setup_as_string();
            } else if (prop.ep.type == PropertyType.FILENAME)
            {
                setup_as_filename();
            }
            else
            {
                GLib.error("Unknown type: %p %i",(void *)prop.ep, prop.ep.type);
            }
            this.show_all();
        }
    }
    /**
     * Edit an Entry
     */
    class Editor : Gtk.VBox
    {
        private Entry entry;
        private unowned Gtk.Window parent_window = null;
        private Gtk.Entry name_entry = null;
        private Gtk.Entry hostname_entry = null;

        private Gtk.ToolItem add_rule_button = null;
        private Gtk.Switch enable_switch = null;

        private Gtk.Label title_label = null;

        private Gtk.HBox enable_hbox = null;
        private Gtk.HBox name_hbox = null;
        private Gtk.HBox hostname_hbox = null;

        private Gtk.VBox prop_vbox = null;

        private void fill_settings_list()
        {
            int i = 0;
            /* Clear the list */
            foreach(var child in prop_vbox.get_children())
            {
                child.destroy();
            }
            var sg = new SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

            foreach(unowned SSHConf.Property prop in entry.settings)
            {
                if(prop.ep.type == PropertyType.LOCAL_FORWARD)
                {
                    var entry_edit = new EditorPropLocalForward(entry,prop,sg);
                    prop_vbox.pack_start(entry_edit, false, false, 0);
                }
                else
                {
                    var entry_edit = new EditorPropGeneric(entry,prop,sg);
                    prop_vbox.pack_start(entry_edit, false, false, 0);
                }
            }
            prop_vbox.show_all();

        }
        construct
        {

            title_label = new Label("");
            title_label.set_markup("<span size='xx-large' weight='bold'>Entry settings</span>");
            this.pack_start(title_label, false, false, 0);
            title_label.set_alignment(0f, 0.5f);
            title_label.set_padding(6,6);

            int i=0;

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

            enable_switch.notify["active"].connect((source) =>
            {
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
            name_entry.changed.connect((source) =>
            {
                if((source as Gtk.Entry).get_text() != entry.name)
                {
                    entry.name = (source as Gtk.Entry).get_text();
                }
                if(entry.validate_pattern(entry.name))
                {
                    name_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-yes");
                }
                else
                {
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
            hostname_entry.changed.connect((source) =>
            {
                if((source as Gtk.Entry).get_text() != entry.hostname)
                {
                    entry.hostname = (source as Gtk.Entry).get_text();
                }
                if(entry.validate_hostname(entry.hostname))
                {
                    hostname_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-yes");
                }
                else
                {
                    hostname_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, "gtk-no");
                }
            });
            hostname_hbox.pack_start(label, false, false, 0);
            hostname_hbox.pack_start(hostname_entry, true, true, 0);
            this.pack_start(hostname_hbox, false, false,3);

            var sw = new Gtk.ScrolledWindow(null,null);
            sw.shadow_type = Gtk.ShadowType.ETCHED_IN;

            var event = new Gtk.EventBox();
            event.set_visible_window(true);

            event.style_updated.connect((source)=>
            {

                stdout.printf("style updated\n");
                    var context2 = event.get_style_context();
                    var path = new Gtk.WidgetPath();

                    typeof(Gtk.TreeView).class_ref();
                    path.append_type(typeof(Gtk.Widget));
                    context2.set_path(path);
                    context2.add_class("view");

                    Gdk.RGBA bg_color;
                    context2.get_background_color(Gtk.StateFlags.NORMAL, bg_color);
                    source.override_background_color(Gtk.StateFlags.NORMAL, bg_color);
            });

            prop_vbox = new Gtk.VBox(false, 6);
            var alivp = new Gtk.Alignment(0,0,1,0);
            alivp.set_padding(6,6,12,6);
            alivp.add(prop_vbox);
            event.add(alivp);
            sw.add_with_viewport(event);
            this.pack_start(sw, true, true, 0);

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
            (add_rule_button as Gtk.ToolButton).clicked.connect((source) =>
            {
                add_entry();
            });

            bbox.insert(add_rule_button, 0);

            this.pack_start(bbox, false, false, 0);

        }

        private void add_entry()
        {
            /* popup a dialog with the different types */
            var dialog = new Gtk.MessageDialog(parent_window,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.QUESTION,
                Gtk.ButtonsType.OK_CANCEL,
                "Add a property of type:");
            var combo = new Gtk.ComboBoxText();
            (dialog.get_message_area() as Gtk.Box).pack_end(combo,false,false,0);
            combo.show();

            foreach(var ep in SSHConf.KEYS)
            {
                if(ep.multi_instances || !entry.has_prop_key(ep.name))
                {
                    combo.append_text(ep.name);
                }
            }
            combo.set_active(0);
            switch(dialog.run())
            {
                case Gtk.ResponseType.OK:
                    string val = combo.get_active_text();
                    if(val != null)
                    {
                        entry.new_prop(val);
                    }
                    break;
                default:
                    break;
            }
            dialog.destroy();
        }

        ~Editor()
        {
            stdout.printf("~Editor\n");
        }
        public Editor (Gtk.Window parent, Entry entry)
        {
            this.parent_window = parent;
            this.entry = entry;

            enable_switch.set_active(this.entry.enabled);

            name_entry.set_text(entry.name);
            this.entry.notify["name"].connect(() =>
            {
                name_entry.set_text(this.entry.name);
            });

            hostname_entry.set_text(entry.hostname);
            this.entry.notify["hostname"].connect(() =>
            {
                hostname_entry.set_text(this.entry.hostname);
            });

            this.entry.notify["enabled"].connect(() =>
            {
                if(this.entry.enabled != enable_switch.get_active())
                {
                    enable_switch.set_active(this.entry.enabled);
                }

            });
            this.entry.changed.connect((what) =>
            {
                if(what == SSHConf.Entry.ChangedType.PROPERTY_ADDED)
                {
                    fill_settings_list();
                }
            });
            fill_settings_list();
            this.show_all();

            /**
             * If default settings modify editor a bit
             */
            if(entry is DefaultEntry)
            {
                title_label.set_markup("<span size='xx-large' weight='bold'>Default settings</span>");
                stdout.printf("Default entry\n");

                enable_hbox.hide();
                name_hbox.hide();
                hostname_hbox.hide();
            }
        }
    }
}

