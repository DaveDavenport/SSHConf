namespace Glue
{
    [CCode (cheader_filename = "gtk/gtk.h", cname="gtk_tree_model_rows_reordered")]
    public void rows_reordered (Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter? iter, void* new_order);
}
