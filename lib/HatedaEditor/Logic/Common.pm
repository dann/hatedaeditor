package HatedaEditor::Logic::Common;
use strict;
use warnings;
use HatedaEditor;

sub quit {
    exit;
}

sub show_about {
    HatedaEditor->cui->dialog(
        -fg      => 'yellow',
        -bg      => 'black',
        -title   => 'About:',
        -message => <<EOT);
Author:
  Dann <techmemo at gmail.com

Version:
  0.002
EOT

}

sub show_help {
    HatedaEditor->cui->dialog(
        -fg      => 'yellow',
        -bg      => 'black',
        -title   => 'Help:',
        -message => <<EOT);
Basic Commands:
 j/k/h/l/arrow keys - move cursor
 e       - open page for edit
 r       - choose from recently changed pages
 g       - choose hatena group

Awesome Commands:
 0/G - move to beginning/end of page
 s   - search
 u   - show the uri for the current entry
 m   - show page metadata (categor)
 P   - New blog post

Find:
 / - find forward
 ? - find backwards 

Ctrl-q / Ctrl-c / q - quit
EOT

}

1;
