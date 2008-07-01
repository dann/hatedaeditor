package HatedaEditor::Logic::Viewer;
use strict;
use warnings;
use HatedaEditor;
use Encode;
use Data::Dumper;

sub edit {
    HatedaEditor->cui->status('Editing diary...');
    HatedaEditor->cui->leave_curses;

    my $date  = HatedaEditor->cui->question( -question => 'Date: ' );
    my $entry = get_diary_entry($date);
    my $fh    = File::Temp->new
        or die "Can't create a temp file";
    my $body  = $entry->{body};
    my $title = $entry->{title};
    Encode::from_to( $body,  'euc-jp', 'utf8' );
    Encode::from_to( $title, 'euc-jp', 'utf8' );

    $fh->print($body);

    my $editor = $ENV{EDITOR} || 'vim' || 'emacs';
    if ( $editor eq 'vim' || $editor eq 'vi' ) {
        system( $editor, "-c", "set filetype=hatena",
            "-c", "syntax on", "-c", "set background=dark",
            $fh->filename
        );
    }
    else {
        system( $editor, $fh->filename );
    }

    my $new_entry_text = _read_file( $fh->filename );
    HatedaEditor->viewer->text($new_entry_text);

    # FIXME
    HatedaEditor->api->update_day(
        {   title => $title,
            body  => $new_entry_text,
            date  => $date,
        }
    );

    $fh->close;

    HatedaEditor->cui->nostatus;
    HatedaEditor->cui->reset_curses;
}

sub get_diary_entry {
    my $date = shift;
    my $post = HatedaEditor->api->retrieve_day( { date => $date, } );
    return $post;
}

sub _read_file {
    my $filename = shift;
    open( my $fh, $filename ) or die "unable to open $filename $!\n";
    my $new_content;
    {
        local $/;
        $new_content = <$fh>;
    }
    close $fh;
    return $new_content;
}

sub load_entry {
    my $date;
    HatedaEditor->cui->status("Getting diary ...");
    my $entry      = get_diary_entry($date);
    my $entry_text = $entry->body;
    Encode::from_to( $entry_text, 'euc-jp', 'utf8' );

    HatedaEditor->viewer->text($entry_text);
    HatedaEditor->cui->nostatus;
}

1;
