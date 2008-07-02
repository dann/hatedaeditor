package HatedaEditor::Logic::GroupListbox;
use strict;
use warnings;
use HatedaEditor;

sub onchange {
    my $w     = shift;
    my $group = $w->get();
    HatedaEditor->current_group($group);
    unless ( $group eq 'NONE') {
        HatedaEditor->_setup_api($group);
    }
    HatedaEditor->win->delete('listbox');
    HatedaEditor->win->draw;
}

1;
