/* sshconf-entry-model.vala
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

namespace SSHConf
{
    class EntryModel : GLib.Object, Gtk.TreeModel, Gtk.TreeSortable
    {
        public enum Columns
        {
            ENTRY = 0,
            NAME,
            HOSTNAME,
            NUM_COLUMNS
        }
        private GLib.List<Entry> entries;
        private int stamp = 1;

        ~EntryModel()
        {
            entries = null;
            stdout.printf("~EntryModel\n");
        }

        public GLib.Type get_column_type(int index)
        {
            switch((EntryModel.Columns)index)
            {
                case Columns.ENTRY:
                    return typeof(SSHConf.Entry);
                case Columns.NAME:
                case Columns.HOSTNAME:
                    return typeof(string);
                default:
                    GLib.error("Unknown column");
            }
        }

        public Gtk.TreeModelFlags get_flags()
        {
            return Gtk.TreeModelFlags.LIST_ONLY;
        }

        public bool get_iter(ref Gtk.TreeIter iter, Gtk.TreePath path)
        {
            int[] indices = path.get_indices ();
            unowned GLib.List<Entry> en = entries.nth(indices[0]);
            if(en != null)
            {
                iter = Gtk.TreeIter();
                iter.stamp = this.stamp;
                iter.user_data = en;
                iter.user_data2 = indices[0].to_pointer();
                return true;
            }
            return false;
        }
        /**
         * Get the number of columns in this model
         */
        public int get_n_columns()
        {
            return (int)Columns.NUM_COLUMNS;
        }

        /**
         * Get path from iter
         */
        public Gtk.TreePath? get_path(Gtk.TreeIter iter)
        {
            int index = (int)(iter.user_data2);

            Gtk.TreePath path = new Gtk.TreePath.from_indices(index, -1);
            return path;
        }
        /**
         * get value
         */
        public void get_value(Gtk.TreeIter iter, int column,out Value val)
        {
            val = Value(this.get_column_type(column));
            Entry? en =  ((List<Entry>)iter.user_data).data;
            switch((EntryModel.Columns)column)
            {
                case Columns.ENTRY:
                    val.set_object(en);
                    return;
                case Columns.NAME:
                    val.set_string(en.name);
                    return;
                case Columns.HOSTNAME:
                    val.set_string(en.hostname);
                    return;
                default:
                    GLib.error("Unknown column");
            }
        }

        /**
         * Get the children of iter %parent (always false)
         * if parent is null return first node
         */
        public bool iter_children(ref Gtk.TreeIter iter, Gtk.TreeIter? parent)
        {
            if(parent != null) return false;
            return this.iter_first(ref iter);
        }
        public bool iter_has_child(Gtk.TreeIter iter)
        {
            return false;
        }
        public int iter_n_children(Gtk.TreeIter? iter)
        {
            if(iter != null) return 0;
            return (int)entries.length();
        }
        public bool iter_next(Gtk.TreeIter iter)
        {
            unowned List<Entry> entry = ((List<Entry>)iter.user_data);

            if(entry.next == null) return false;

            iter.stamp = this.stamp;
            iter.user_data = entry.next;
            iter.user_data2 = ((int)(iter.user_data2)+1).to_pointer();
            return true;
        }
        public bool iter_nth_child(ref Gtk.TreeIter iter, Gtk.TreeIter? parent, int n)
        {
            // no children
            if(parent != null) return false;
            unowned List<Entry>? en = entries.nth(n);
            if(en == null) return false;

            iter.stamp = this.stamp;
            iter.user_data = (void*)en;
            iter.user_data2 = n.to_pointer();

            return true;
        }
        public bool iter_parent(ref Gtk.TreeIter iter, Gtk.TreeIter child)
        {
            return false;
        }

        public void ref_node(Gtk.TreeIter iter)
        {
        }
        public void unref_node(Gtk.TreeIter iter)
        {
        }
        public bool iter_first(ref Gtk.TreeIter iter)
        {
            if(entries.length() == 0) return false;
            iter.stamp = this.stamp;
            iter.user_data = (void*)entries.first();
            iter.user_data2 = (1).to_pointer();
            return true;
        }

        private void entry_changed(Entry en)
        {
            int index = entries.index(en);
            Gtk.TreePath rpath = new Gtk.TreePath.from_indices(index, -1);
            Gtk.TreeIter riter;
            if(this.get_iter(out riter, rpath))
            {
                row_changed(rpath, riter);
                sort_columns();
            }
        }
        public Gtk.TreePath add_entry (Entry entry)
        {
            this.stamp++;
            entries.append(entry);
            Gtk.TreePath path = new Gtk.TreePath.from_indices(entries.length()-1,-1);
            Gtk.TreeIter iter;
            if(this.get_iter(out iter, path))
            {
                row_inserted(path, iter);
            }
            else
            {
                GLib.error("Failed to get iter for new node");
            }
            entry.notify["name"].connect((source,spec)=>{
                entry_changed((source as SSHConf.Entry));
            });
            sort_columns();
            path = new Gtk.TreePath.from_indices(entries.index(entry),-1);
            return path;
        }

        public void remove_entry (Entry entry)
        {
            this.stamp++;
            unowned List<Entry> en = entries.find(entry);
            if(en != null)
            {
                int index = entries.index(entry);
                Gtk.TreePath path = new Gtk.TreePath.from_indices(index, -1);
                Entry e = (owned)en.data;
                entries.delete_link(en);
                e = null;
                /* signal row deleted */
                row_deleted(path);
            }
        }
        /** Sortable interface
         */
        private static int sort_entries_by_name(Entry? a, Entry? b)
        {
            if(a == null && b == null) return 0;
            else if(a == null) return -1;
            else if(b == null) return 1;
            return a.name.collate(b.name);
        }
        private void sort_columns()
        {
            List<Entry> list_copy = null;//entries.copy();
            foreach(Entry a in entries) {
                list_copy.append(a);
            }
            list_copy.sort(sort_entries_by_name);

            int[] new_order = new int[list_copy.length()];
            int i  =0;
            foreach(Entry a in list_copy)
            {
                new_order[i] = entries.index(a);
                i++;
            }
            entries = (owned)list_copy;
            this.stamp++;
            GLib.debug("reordered rows");
            var path = new Gtk.TreePath();
            Glue.rows_reordered(this,path,null, new_order);
        }
        private Columns sort_column = Columns.NAME;
        private Gtk.SortType sort_order = Gtk.SortType.ASCENDING;
        public bool has_default_sort_func()
        {
            return true;
        }
        public bool get_sort_column_id (out int column_id, out Gtk.SortType column_sort_order)
        {
            if(sort_column != Columns.NAME) return false;
            column_id = sort_column;
            column_sort_order = sort_order;
            return true;
        }
        public void set_sort_column_id(int column_id, Gtk.SortType type)
        {
            /* Do nothing, we can only sort on name */
        }
        public void set_sort_func(int column_id, owned Gtk.TreeIterCompareFunc func)
        {
            /* Setting sort func is not supported */
            GLib.error("Setting sort func is not supported");
        }
        public void set_default_sort_func(owned Gtk.TreeIterCompareFunc func)
        {
            /* Do nothing, we can only do our sort */
            GLib.error("Default sort is not supported");
        }
    }
}
