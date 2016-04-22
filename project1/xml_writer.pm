#!/usr/bin/env perl

#JSN:xloffa00

#Author: Pavol Loffay, xloffa00@stud.fit.vutbr.cz
#Date: 30.3.2012
#Project: projekt 1. do predmetu IPP - pomocny modul pre jsn.pl
#Description: pomocny modul pre jsn.pl
#             implementacia XML::Writera - pomaha vypisovat xml tagy

package xml_writer;

#parameter nazov vysledneho suboru
#parameter velkost odsadzenia
sub new
{
    my $class = shift;
    my $self =
    {
        _file => shift,
        _indent => shift,
        _actual_indent => 0,
    };

    bless $self, $class;
    return $self;
}

#xml hlavicka
#vypise xml hlavicku
#volat bez parametra
sub decl_utf8
{
    my ($self) = @_;

    defined $self->{_file} ?
        $self->{_file}->print('<?xml version="1.0" encoding="UTF-8"?>', "\n") :
        print '<?xml version="1.0" encoding="UTF-8"?>', "\n";
}

#xml start_tag
#parameter obsah tagu
sub start_tag
{
    my( $self, $param ) = @_;

    my $cout = 0;
    while ($cout < $self->{_actual_indent})
    {
        defined $self->{_file} ? 
            $self->{_file}->print(' ') :
            print ' ';
        $cout++;
    }

    $self->{_actual_indent} = $self->{_actual_indent} + $self->{_indent};

    defined $self->{_file} ? 
        $self->{_file}->print('<', $param, ">\n") :
        print '<', $param, ">\n";
}

#xml end_tag
#parameter obsah tagu
sub end_tag
{
    my ( $self, $param) = @_;

    $self->{_actual_indent} = $self->{_actual_indent} - $self->{_indent};
    my $cout = 0;
    while ($cout < $self->{_actual_indent})
    {
        defined $self->{_file} ? 
            $self->{_file}->print(' ') :
            print ' ';
        $cout++;
    }

    defined $self->{_file} ? 
        $self->{_file}->print('</', $param, ">\n") :
        print '</', $param, ">\n";
}

#xml empty_tag
#parameter obsah tagu
sub empty_tag
{
    my ($self, $param) = @_;

    my $cout = 0;
    while ($cout < $self->{_actual_indent})
    {
        defined $self->{_file} ? 
            $self->{_file}->print(' ') :
            print ' ';
        $cout++;
    }

    defined $self->{_file} ? 
        $self->{_file}->print('<', $param, "/>\n") :
        print '<', $param, "/>\n";
}

#xml characters, vypise text
#paramter text
sub characters
{
    my ($self, $param) = @_;

    my $cout = 0;
    while ($cout < $self->{_actual_indent})
    {
        defined $self->{_file} ? 
            $self->{_file}->print(' ') :
            print ' ';
        $cout = $cout + 1;
    }

    defined $self->{_file} ? 
        $self->{_file}->print($param, "\n") :
        print $param, "\n";
}

1;

