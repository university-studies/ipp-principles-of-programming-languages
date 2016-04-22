#!/usr/bin/env perl

#JSN:xloffa00

#Name: Pavol Loffay, xloffa00@stud.fit.vutbr.cz
#Date: 23.02.2012
#Project: projekt do predmetu IPP, prevod JSON do XML

#TODO: otestovat moj regular na spravnost XML znaciek

use strict;
use Getopt::Long;
#use Getopt::Long qw(:config gnu_compat);
use JSON::XS;
use XML::Writer;
use IO::File;
#use XML::RegExp;
use Data::Types qw(:all);
use Data::Dumper;
use xml_writer;

# don't output names where feasible
$Data::Dumper::Terse = 1;
# turn off all pretty print
$Data::Dumper::Indent = 0;         

undef $/;

#pocet parametrov prikazovej riadky
my $argc = @ARGV;

#constanty pouzite pre navratove hodnoty
use constant BAD_PARAM => 1;
#neexistujuci vstupny subor/nepodarilo sa ho otvorit
use constant BAD_IN => 2;
#vystupny subor sa nepodarilo otvorit
use constant BAD_OUT => 3;
#vstupny subor je zleho formatu
use constant BAD_FORMAT_IN => 4;
#XML znacka obsahuje nepovolene znaky
use constant INVALID_XML => 51;
#XML znacka(root-element, array-element, item-element) obsahuje nepovolene znaky 
use constant INVALID_XML_U => 50;

#konstanta pre nahradenie nepovelenych znakov c xml znacke <znacka>
my $XML_INVALID_ELEMENT = 
    '[\ \!\"\#\$\%\&\'\(\)\*\+\,\.\/\;\<\=\>\?\@\[\]\^\`\{\|\}\~]';
#premenne ktore obsahuju regularne vyrazi na identifikovanie spravneho XML nazvu
my $NameStartChar =
'([:]|[A-Z]|[_]|[a-z]|[\x{C0}-\x{D6}]|[\x{D8}-\x{F6}]|[\x{F8}-\x{2FF}]|[\x{370}-\x{37D}]|[\x{37F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])';
my $name_char_characters =
'([-]|[\.]|[0-9]|[\xB7]|[\x{0300}-\x{036F}]|[\x{203F}-\x{2040}])';
my $NameChar = "($NameStartChar|$name_char_characters)";
my $Name = "($NameStartChar($NameChar*))";

#premenne pre parametre skriptu
my $help = 0;
my @input;
my @output;
my $no_head = 0;
my @root_element;
my @array_name;
my @item_name;
my $string_to_text = 0;
my $number_to_text = 0;
my $to_elements = 0;
my $problem_signs = 0;
my $index_item = 0;
my $array_size = 0;
my @increment_counter;
my $padding = 0;

#####################################################################
#                Spracovanie a kontrola parametrov
#####################################################################
#spracovanie parametrov z prikazoveho riadka
Getopt::Long::Configure('bundling');

GetOptions('help+' => \$help,
           'input=s' => \@input,
           'output=s' => \@output,
           'n+' => \$no_head,
           'r=s' => \@root_element,
           'array-name=s' => \@array_name,
           'item-name=s' => \@item_name,
           's+' => \$string_to_text,
           'i+' => \$number_to_text,
           'l+' => \$to_elements,
           'c+' => \$problem_signs,
           'a|array-size+' => \$array_size,
           't|index-items+' => \$index_item,
           'start=i' => \@increment_counter,
           'padding+' => \$padding) or exit(BAD_PARAM);   

#osetrenie opakovania sa parametrov
if ($help > 1 || $no_head > 1 || $string_to_text > 1 || $number_to_text > 1
    || $to_elements > 1 || $problem_signs > 1 || $array_size > 1 
    || @input > 1 || @output > 1 || @array_name > 1 || @item_name > 1
    || @increment_counter > 1 || @root_element > 1 || $index_item > 1
    || $padding > 1)
{
    print_error("Chybne parametre: niektory parameter sa opakoval!\n",
        BAD_PARAM);
}

#osetrenie ze help moze byt iba sam
if ($help >= 1 && $argc > 1)
{
    print_error("Chybne parametre: parameter help sa nemoze kombinovat!\n",
        BAD_PARAM);
}

#osetrenie ze nebol zadany iny parameter
if ($argc != ($help + $no_head + $string_to_text + $number_to_text +
             $to_elements + $problem_signs + $array_size + @input + @output +
             @array_name + @item_name + @increment_counter + @root_element +
             $index_item + $padding))
{
    print_error("Chybne parametre: bol zadany nespravny parameter!\n",
        BAD_PARAM)
}

#ak je --start=n, n < 0 hlasit chybu
#TODO ak bude zadany bez -t ci sa ma hlasit chyba
if (@increment_counter == 1 && $index_item == 0)
{
    print_error("Chybne parametre: --start=n sa musi kombinovat s -t\n",
                BAD_PARAM);
}
if ($increment_counter[0] < 0)
{   
    print_error("Chybne parametre: --start=n, n musi byt v <0,...>\n",
                BAD_PARAM);
}

#kontrola parametru -r=root-element ci je validna XML znacka
if (@root_element == 1)
{
    if (@root_element[0] =~ /^=.*/)
    {
        @root_element[0] = substr(@root_element[0], 1);
    }
    utf8::decode($root_element[0]);
    if (! ($root_element[0] =~ /^$Name$/))
    {
        print_error("Chyba: nepovolena XML znacka - root-element!\n",
            INVALID_XML_U);
    }
}

my $array_name = "array";
#kontrola parametru --array-name=array-element ci je validna XML znacka
if (@array_name == 1)
{
    $array_name = shift @array_name;
    if ($array_name =~ /^=.*/)
    {
        $array_name = substr($array_name, 1);
    }
    utf8::decode($array_name);
    if (! ($array_name =~ /^$Name$/))
    {
        print_error("Chyba: nepovolena XML znacka - array-name!\n",
            INVALID_XML_U);
    }
}

my $item_name = "item";
#kontrola parametru --item-value=item-element ci je validna XML znacka
if (@item_name == 1)
{
    $item_name = shift @item_name;
    if ($item_name =~ /^=.*/)
    {
        $item_name = substr($item_name, 1);
    }
    utf8::decode($item_name);
    if (! ($item_name =~ /^$Name$/))
    {
        print_error("Chyba: nepovolena XML znacka - item-name!\n", 
            INVALID_XML_U);
    }
}

#######################################################################
#                Otvaranie suborov, vytvaranie objektov
#######################################################################
if ($help == 1)
{
    help_print();
}

#VSTUPNY SUBOR
#ak input == 1 tak bol zadany vstupny subor
my $in_file;
if (@input == 1)
{
    open $in_file, "<", @input or 
        print_error("Chyba pri otvoreni vstupneho suboru!\n", BAD_IN);
}
else
{
    $in_file = *STDIN;
}

#nacitanie JSON textu 
my $json_text;
my $valid_jsn_file = eval { $json_text = JSON::XS->new->utf8->decode (<$in_file>)};
if (! $valid_jsn_file)
{
    print_error("Chyba: zly format vstupneho suboru!\n",
                 BAD_FORMAT_IN);
}

#zatvaranie ak sa citalo z suboru 
if (@input == 1)
{
    close $in_file;
}

if ( !(ref($json_text) ne "HASH" || ref($json_text) ne "ARRAY") )
{
    print_error("Chyba: zly format vstupneho suboru\n",
        BAD_FORMAT_IN);
}

#VYSTUPNY SUBOR
#ak output == 1 je zadany vystupny subor 
my $out_file = <NOT_DEFINED>;
my $open_out_file = 0;
if (@output == 1)
{
    $out_file = new IO::File(">@output") or 
        print_error("Chyba pri otvoreni vystupneho suboru!\n", BAD_OUT);
    $open_out_file = 1;
}

#vytvorenie XML objektu, koli spravnemu kodovaniu vystupneho suboru
my $xml_writer_orig = new XML::Writer(OUTPUT => $out_file,
                                  DATA_INDENT => 4, DATA_MODE => 1, 
                                  CHECK_PRINT=> 1, UNSAFE => 1, ENCODING =>
                                  'utf-8');
#vytvorenie mojho xml writeru
my $xml_writer = new xml_writer($out_file, 4);

#######################################################################
#                    Zaciatok vytvarania XML dokumentu
#######################################################################


#parameter -n negenerovat hlavicku
if ($no_head == 0)
{
    $xml_writer->decl_utf8();
}

#$out_file @root_element;
if (@root_element == 1)
{
    $xml_writer->start_tag(@root_element[0]);
}

#zavolanie funckie na prevod JSON2XML
json2xml($json_text);

if (@root_element == 1)
{
    $xml_writer->end_tag(@root_element[0]);
}

#ukonci pracu s xml suborom, prina \n na konci...
$xml_writer_orig->end();

#zavretie vystupneho suboru
if (@output == 1)
{
    $open_out_file = 0;
    $out_file->close();
}

exit(0);

#################################################################
#                           Koniec
#################################################################

#funcia na prevod JSON2XML, vola sa rekurzivne
#parameter JSON_OBJEKT
sub json2xml
{
    my $json_item = shift;

    #ref zisti akeho typu je premenna HASH,ARRAY ..
    if (ref($json_item) eq "HASH")
    {
        my $key;
        my $value;

        #prejde celu hash
        while (($key, $value) = each %$json_item)
        {
            #v hash je HASH alebo ARRAY
            if ((ref($value) eq "HASH") || ref($value) eq "ARRAY")
            {
                #otesovania a upravenie XML znacky
                $key = substituite($key);

                $xml_writer->start_tag($key);
                json2xml($value);
                $xml_writer->end_tag($key);
            }
            else
            {
                json2xml($value, $key);
            }
        }
    }
    #hodnota je pole
    elsif (ref($json_item) eq "ARRAY")
    {
        #polozky pola su cislovane => musi byt pridany atribut index
        my $start_index = ((scalar @increment_counter) == 0) ? 1 :
            $increment_counter[0];
        my $index = $start_index;

        #udava kolko cifier ma najvacsi index pola
        #pre --padding
        my $max_digit;
        #vypocitanie cifier
        if ($padding == 1 && $index_item == 1)
        {
            #vypocita na kolko cifier bude najvacsi index
            #prebehne iba raz
            my $max_index = @$json_item + $start_index - 1;
            while ($max_index > 0)
            {
                $max_digit++;
                $max_index = int($max_index / 10);
            }
        }

        #ak bol zadany parameter -a|--array-size
        #treba vypisat atribut size s velkostou pola
        if ($array_size == 1)
        {
            my $array_size = @$json_item; #alebo scalar @$array_size
            $xml_writer->start_tag($array_name." size=".'"'.$array_size.'"');
        }
        else
        {
            $xml_writer->start_tag($array_name);
        }

        #prejde vsetky polozky pola
        foreach my $array_item (@$json_item)
        {
            #polozky pola nie su cislovane, nie je pridany atribut index
            if ($index_item == 0)
            {
                #polozka v poli je HASH alebo ARRAY
                if (ref($array_item) eq "HASH" || ref($array_item) eq "ARRAY")
                {
                    $xml_writer->start_tag($item_name);
                    json2xml($array_item);
                    $xml_writer->end_tag($item_name);
                }
                else
                {
                    #polozka v poli nie je HASH ani ARRAY
                    #ak je null
                    if (defined($array_item) == "false")
                    {
                        elements_or_atributes("null", $item_name);
                    }
                    #ak je true, false
                    elsif (JSON::XS::is_bool($array_item) == 1)
                    {
                        my $boolean = ($array_item == 1) ? "true" : "false";
                        elements_or_atributes($boolean, $item_name);
                    }
                    #je hocico ine..
                    else
                    {
                        #problematicke znaky ako <&> sa maju nahradit &amp;...
                        #empty tag to robi automaticky
                        
                        #zaokruhlenie cisla
                        $array_item = (is_number($array_item) == 1) ?
                        my_round($array_item) : $array_item;

                        my $item = scalar $array_item;
                        if ($problem_signs == 1)
                        {
                            $item = escape($item);
                        }

                        my $in = $item_name.' value="'.$item.'"';
                        $xml_writer->empty_tag($in);
                    }
                }
            }
            #polozky v poli su cislovane - atribut index
            else
            {
                my $index_print;

                #pridanie nul --padding
                if ($padding == 1)
                {
                    
                    my $actual_digit = 0;
                    my $index2 = $index;
                    while ($index2 > 0)
                    {
                        $actual_digit++;
                        $index2 = int($index2 / 10);
                    }

                    my $zeros;
                    while ($max_digit > $actual_digit)
                    {
                         $actual_digit++;
                         $zeros = $zeros . "0";
                    }
                 
                    #pridanie nul
                    $index_print = $zeros . $index;
                }
                else
                #nuly sa nepridavaju
                {
                    $index_print = $index;
                }

                #polozka v poli je HASH alebo ARRAY
                if (ref($array_item) eq "HASH" || ref($array_item) eq "ARRAY")
                {
                    $xml_writer->start_tag($item_name.' index="'.$index_print.'"');
                    json2xml($array_item);
                    $xml_writer->end_tag($item_name);
                }
                else
                {
                    #polozka v poli nie je HASH ani ARRAY
                    #ak je null
                    if (defined($array_item) == "false")
                    {
                        elements_or_atributes("null", $item_name, 1,
                            $index_print);
                    }
                    #ak je true, false
                    elsif (JSON::XS::is_bool($array_item) == 1)
                    {
                        my $boolean = ($array_item == 1) ? "true" : "false";
                        elements_or_atributes($boolean, $item_name, 1,
                            $index_print);
                    }
                    #je hocico ine..
                    else
                    {
                        #problematicke znaky ako <&> sa maju nahradit &amp;...
                        #empty tag to robi automaticky
                        
                        #zaokruhlenie cisla
                        $array_item = (is_number($array_item) == 1) ?
                        my_round($array_item): $array_item;

                        if ($problem_signs == 1)
                        {
                            $array_item = escape($array_item);
                        }

                        my $temp = scalar $array_item;
                        my $item = $item_name.' index="'.$index_print.'"'.
                                   ' value="'.$temp.'"';
                        $xml_writer->empty_tag($item);
                    }
                }
                $index++;
            }
        }

        $xml_writer->end_tag($array_name);
    }
    #retazec, true, false, null..
    else
    {
        my $key = shift;
        $key = substituite($key);

        #hodnoty false, true, null
        if (defined($json_item) == "false" || JSON::XS::is_bool($json_item) == 1)
        {
            #true, false, null sa transformuju na <true/>...
                if (defined($json_item) == "false")
                {
                    elements_or_atributes("null", $key);
                }
                elsif (JSON::XS::is_bool($json_item) == 1)
                {
                    my $boolean = ($json_item == 1) ? "true" : "false";
                    elements_or_atributes($boolean, $key);
                }
        }
        else
        #cislo alebo retazec
        {
            #kontrola XML znacky
            $key = substituite($key);
            
            #cislo
            if (is_number($json_item) == 1)
            {
                #zaokruhlenie cisla
                $json_item = my_round($json_item);

                if ($number_to_text == 1)
                {
                    $xml_writer->start_tag($key);
                    $xml_writer->characters($json_item);
                    $xml_writer->end_tag($key);
                }
                else
                {
                    $xml_writer->empty_tag($key.' value="'.$json_item.'"');
                }
            }
            #retazec
            else
            {
                if ($problem_signs == 1)
                {
                    $json_item = escape($json_item);
                }

                if ($string_to_text == 1)
                {
                    $xml_writer->start_tag($key);
                    $xml_writer->characters($json_item);
                    $xml_writer->end_tag($key);
                }
                else
                {
                    $xml_writer->empty_tag($key.' value="'.$json_item.'"');
                }
            }
        }
    }
}

#####################################################################
#                        Pomocne funkcie
#####################################################################

#zisti ci je parameter cislo
#ak je cislo vrati 1, inak 0
sub is_number
{
   my $param = shift;
   my $param = Dumper($param);
   if (is_int($param) or is_real($param) or is_float($param) or
       is_decimal($param))
   {
       return 1;
   }

   return 0;
}

exit(0);

#pomocna funkcia pre parameter -l 
#ktory transformuje hodnoty literalov true,false,null na <true/>..
#parametrom funcie je <retazec "true, false, .."> <znacka> <index>
#pouzitie elements_or_atributes "true" $key $index_true $index
sub elements_or_atributes
{
    my $value = shift;
    my $key = shift;

    #index- atribut pri poli -t|--index-item
    my $index_true = shift;
    my $index = shift;

    #prida sa atribut index - iba v poi
    if ($index_true == 1)
    {
        if ($to_elements == 1)
        {
            $xml_writer->startTag($key.' index="'.$index.'"');
            $xml_writer->empty_tag($value);
            $xml_writer->end_tag($key.' index="'.$index.'"');
        }
        else
        {
            $xml_writer->empty_tag($key.' index="'.$index.'" value="'.$value.'"');
        }
    }
    else
    {
        if ($to_elements == 1)
        {
            $xml_writer->start_tag($key);
            $xml_writer->empty_tag($value);
            $xml_writer->end_tag($key);
        }
        else
        {
            $xml_writer->empty_tag($key.' value="'.$value.'"');
        }
    }
}

#zaokruhli parameter - cislo
#vrati zaokruhlene cislo na cele pozicie - integer
sub my_round
{
    my $param = shift;

    #ak je cislo zaporne 
    #$zaporne nastavi na 1 a cislo prevedie na kladne
    my $zaporne = ($param < 0) ? 1 : 0;
    $param = ($zaporne == 1) ? -$param : $param;

    my $desatinna = sprintf("%.7f", $param);
    
    my $cela = sprintf("%.0f", $param);

    $cela = ($desatinna >= 0.5) ? $cela++ : $cela;

    $cela = ($zaporne == 1) ? -$cela : $cela;

    return $cela;
}

#Vypise napovedu
sub help_print
{
    print "Skript pre konverziu JSON formatu do XML
           Pouzitie parametrov:
           --help : vypise napovedu
           --input=filename : nazov vstupneho suboru, ak chyba stdin
           --output=filename : nazov vystupneho suboru, ak chyba stdout
           -n : negeneruje sa XML hlavicka
           -r=root-element : meno paroveho korenoveho elementu obalujuci
           vysledok
           --array-name=array-element : umoznuje premenovat element obalujuci
           pole z implicitnej hodnoty array na array-element
           --item-name=item-element : umoznuje zmenit meno elementu pre prvky
           pola
           -s :  hodnoty dvojic typu string budu transformovane na textove elementy
           namiesto atributov
           -i : hodnoty dvojic typu number budu transformovane na textove
           elementy  namiesto atributov
           -l : hodnoty (true, false, null) sa transformuju na <true/> ...
           -c : umozni preklad problematickych znakov (&amp, &lt, &gt)
           -a|--array-size : u pola bude doplneny atribut size s uvedenym poctom
           prvkov v poli
           -t|--index-items : k kazdemu prvku pola bude pridany atribut index
           zacina od 1, pokial nie je zadany --start=n
           --start=n : incializacia inrementalneho citaca pre indexaciu prvkov
           pola, nutno kombinovat s -t|--index-items\n";

           exit(0);
}

# print_error err_message return_value
# vypise err_message na STDERR a ukonci skript s kodom return_value
sub print_error
{
    if ($open_out_file == 1)
    {        
        $out_file->close();
    }
    print STDERR $_[0];
    exit($_[1]);
}

#nahradi nepovolene znaky v xml znacke
#ak vznikne validna xml znacka vrati ju, inak ukonci skript s 51
sub substituite
{
    my $param_key = shift;

    if ( !($param_key =~ /^$Name$/) )
    {        
        $param_key =~ s/$XML_INVALID_ELEMENT/-/g;
        #TODO \\ treba doplnit na --
        $param_key =~ s/\\/--/g;

        if ( !($param_key =~ /^$Name$/) )
        {
            print_error("Chyba: nepovolena XML znacka: $param_key!\n", 
                INVALID_XML);
        }
    }

    return $param_key;
}

#escapuje znaky & < > " '
sub escape
{
    my ($param) = @_;
    
    # &
    $param =~ s/\&/\&amp\;/g;
    # <
    $param =~ s/\</\&lt\;/g;
    # >
    $param =~ s/\>/\&gt\;/g;
    # "
    $param =~ s/\"/\&quot\;/g;
    # '
    $param =~ s/\'/\&apos\;/g;

    return $param;
}

