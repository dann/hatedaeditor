package HatedaEditor::Logic::Viewer;
use strict;
use warnings;
use HatedaEditor;
use Encode;
use Data::Dumper;
use File::Temp;
use Path::Class qw(file);

sub edit {
    my $c = HatedaEditor->cui;
    $c->status('Editing diary...');
    $c->leave_curses;

    my $date = $c->question( -question => 'Date(YYYY-MM-DD): ' );
    unless ($date) {
        $c->reset_curses;
        return;
    }

    unless ( _is_valid_date($date) ) {
        $c->error('Invalid date format!');
        $c->reset_curses;
        return;
    }

    my $entry = _get_diary_entry($date);
    my $fh    = File::Temp->new
        or die "Can't create a temp file";

    my $body  = _get_body_text($entry);
    my $title = _get_title_text($entry);

    $fh->print($body);

    my $filename = $fh->filename;
    _editor($filename);
    my $new_entry_text = _read_file($filename);
    $fh->close;

    $c->status('Updating diary...');
    HatedaEditor->api->update_day(
        {   title => $title,
            body  => $new_entry_text,
            date  => $date,
        }
    );

    HatedaEditor->viewer->text($new_entry_text);
    $c->nostatus;
    $c->reset_curses;
}

sub _get_body_text {
    my $entry = shift;
    my $body  = $entry->{body};
    Encode::from_to( $body, 'euc-jp', 'utf8' );
    return $body;
}

sub _get_title_text {
    my $entry = shift;
    my $title = $entry->{title};
    Encode::from_to( $title, 'euc-jp', 'utf8' );
    return $title;
}

sub _editor {
    my $filename = shift;
    my $editor = $ENV{EDITOR} || 'vim' || 'emacs';
    if ( $editor eq 'vim' || $editor eq 'vi' ) {
        system( $editor, "-c", "set filetype=hatena",
            "-c", "syntax on", "-c", "set background=dark", $filename );
    }
    else {
        system( $editor, $filename );
    }
}

sub _is_valid_date {
    my $date = shift;
    unless ( $date =~ /(\d\d\d\d)-(\d\d)-(\d\d)/ ) {
        return 0;
    }

    return 1;
}

sub _get_diary_entry {
    my $date = shift;
    my $post = HatedaEditor->api->retrieve_day( { date => $date, } );
    return $post;
}

sub _read_file {
    my $filename = shift;
    return file($filename)->slurp;
}

1;
