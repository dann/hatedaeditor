package HatedaEditor::Logic::Viewer;
use strict;
use warnings;
use HatedaEditor;
use Encode;
use File::Temp;
use DateTime;
use DateTime::TimeZone;
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

    _edit_entry($date);
}

sub edit_new_entry {
    my $c            = HatedaEditor->cui;
    my $current_date = _current_ymd();
    $c->status("Creating new diary entry on $current_date");
    $c->leave_curses;

    unless ( _is_valid_date($current_date) ) {
        $c->error('Invalid date format!');
        $c->reset_curses;
        return;
    }
    _edit_entry($current_date);
}

sub _current_ymd {
    my $tzhere = DateTime::TimeZone->new( name => 'local' );
    my $dt = DateTime->now( time_zone => $tzhere );
    $dt->ymd('-');
}

sub _edit_entry {
    my $date  = shift;
    my $c     = HatedaEditor->cui;
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

    $c->nostatus;
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
    if ( HatedaEditor->current_group eq 'NONE' ) {
        Encode::from_to( $body, 'euc-jp', 'utf8' );
    }
    return $body;
}

sub _get_title_text {
    my $entry = shift;
    my $title = $entry->{title};

    if ( HatedaEditor->current_group eq 'NONE' ) {
        Encode::from_to( $title, 'euc-jp', 'utf8' );
    }
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
        warn $editor;
        system( $editor, $filename );
    }
}

sub _is_valid_date {
    my $date = shift;
    unless ( $date =~ /^(\d{4})-(\d{2})-(\d{2})$/ ) {
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
