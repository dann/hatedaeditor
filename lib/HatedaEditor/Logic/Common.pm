package HatedaEditor::Logic::Common;
use strict;
use warnings;
use HatedaEditor;

sub quit {
    exit;
}

sub show_help {
    HatedaEditor->cui->dialog(
        -fg      => 'yellow',
        -bg      => 'black',
        -title   => 'Help:',
        -message => <<EOT);
Basic Commands:
 j/k/h/l/arrow keys - move cursor
 n/N     - move to next/previous link
 space/- - page down/up
 e       - open page for edit
 r       - choose from recently changed pages

Awesome Commands:
 0/G - move to beginning/end of page
 s   - search
 u   - show the uri for the current page
 m   - show page metadata (tags, revision)
 P   - New blog post (read tags from current page)

Find:
 / - find forward
 ? - find backwards 
 (Bad: find n/N conflicts with next/prev link)

Ctrl-q / Ctrl-c / q - quit
EOT

}

1;
