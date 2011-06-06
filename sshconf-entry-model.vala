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
using Gee;

class EntryModel : GLib.Object, Gtk.TreeModel
{
    private GLib.List<Entry> entries;

    public GLib.Type get_column_type(int index)
    {
        return typeof(string);
    }

    public Gtk.TreeModelFlags get_flags()
    {
        return Gtk.TreeModelFlags.LIST_ONLY;
    }
    
    public bool get_iter(out Gtk.TreeIter iter, Gtk.TreePath path)
    {
        int[] indices = path.get_indices ();
        unowned GLib.List<Entry> en = entries.nth(indices[0]);
        if(en != null)
        {
            iter = Gtk.TreeIter();
            // @todo fix stamp to update when list changes 
            iter.stamp = 1;
            iter.user_data = en;
            iter.user_data2 = indices[0].to_pointer();
            return true;
        }
        return false;
    }
    
    public int get_n_columns()
    {
        return 1;
    }
    
    public Gtk.TreePath get_path(Gtk.TreeIter iter)
    {
        
    }

}