#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#SYN:xloffa00

#Author: Pavol Loffay, xloffa00@stud.fit.vutbr.cz
#Date: 6.3.2012
#Project: Projekt 2. do predmetu IPP
#         SYN: Zvyraznenie syntaxe

#pouzite moduly
import getopt;
import sys;
import string;  
import re;      

#konstanty pre navratove hodnoty
RET_BAD_PARAMS = 1;
RET_OK = 0;
RET_BAD_IN_FILE = 2;
RET_BAD_OUT_FILE = 3;
RET_BAD_FORMAT_FILE = 4; 

#formatovacie prikazy
FORMAT_PARAMS = ["bold", "italic", "underline", "teletype"];

def error_exit(exit_value, err_message):
    '''
    @brief Vypise err_message na stderr a 
           ukonci skript s hodnotou exit_value

    @param number - navratova hodnnota skriptu
    @param string - chyba ktora sa vypise
    @return void
    '''
    sys.stderr.write(err_message);
    sys.exit(exit_value);

def print_help():
    '''
    @brief Vypise napovedu a ukonci skript

    @param void
    @return void
    '''
    print("SYN - Zvyraznenie syntaxe\n",
          "--help: vypise tuto napovedu\n",
          "--format=filename: urcenie formatovacieho suboru\n",
          "--input=filename: urcenie vstupneho suboru v utf-8\n",
          "--output=filename: urcenie vystupneho suboru v utf-8\n",
          "--br: prida <br /> na koniec kazdeho riadku povodneho vstupu\n",
          "Formatovaci subor obsahuje <regularny vyraz> <formatovcie parametre>\n",
          "Ak nie je zadany vstupny subor vstup je stdin\n",
          "Ak nie je zadany vystupny subor vystup ide na stdout\n");
    sys.exit(RET_OK);

def params():
    '''
    @brief Spracauje parametre prik. riadku
           vrati zoznam kde budu ulozene parametre
           ktore boli zadane.
           Ak ma parameter mat hodnotu bude ulozena v zozname za parametrom!

    @param void
    @return list - kde su ulozene parametre ktore boli zadane,
                   parametre s hodnotou budu ulozene v zozname hned za
                   parametrom
    '''
    try:
        opts, args = getopt.getopt(sys.argv[1:], "", ["help", "format=", "input=",
                                                  "output=", "br"]);
    except getopt.GetoptError as err:
        error_exit(RET_BAD_PARAMS, "Bol zadany nespravny parameter!\n");

    params_list = [];
    params_counter = 0;

    #opts is list of (option, value)
    for param, value in opts:
        if (param == "--help"):
            if (param in params_list):
                error_exit(RET_BAD_PARAMS, 
                           "Chybne parametre: dva krat zadany parameter!\n");

            params_list.append("--help");
            params_counter += 1;
        elif (param == "--format"):
            if (param in params_list):
                error_exit(RET_BAD_PARAMS,
                           "Chybne parametre: dva krat zadany parameter!\n");
            if (value == "" ):
                error_exit(RET_BAD_PARAMS,
                           "Chybne parametre: --format vyzaduje parameter!\n");

            params_list.append("--format");
            params_list.append(value);
            params_counter += 1;
        elif (param == "--input"):
            if (param in params_list):
                error_exit(RET_BAD_PARAMS, 
                           "Chybne parametre: dva krat zadany parameter!\n");
            if (value == ""):
                error_exit(RET_BAD_PARAMS,
                           "Chybne parametre: --input vyzaduje parameter!\n");

            params_list.append("--input");
            params_list.append(value);
            params_counter += 1;
        elif (param == "--output"):
            if (param in params_list):
                error_exit(RET_BAD_PARAMS, 
                           "Chybne parametre: dva krat zadany parameter!\n");
            if (value == ""):
                error_exit(RET_BAD_PARAMS, 
                           "Chybne parametre: --output vyzaduje parameter!\n");

            params_list.append("--output");
            params_list.append(value);
            params_counter += 1;
        elif (param == "--br"):
            if (params in params_list):
                error_exit(RET_BAD_PARAMS, 
                           "Chybne parametre: dva krat zadany parameter!\n");

            params_list.append("--br");
            params_counter +=1;
        else:
            error_exit(RET_BAD_PARAMS,
                    "Chybne parametre: nespravny parameter!\n");
    
            
    if (len(sys.argv[1:]) != params_counter):
        error_exit(RET_BAD_PARAMS, 
                "Chybne parametre: nespravny parameter!\n");
    return params_list

def parse_format_file(format_data):
    '''
    @brief Funkcia spracuje subor --forma=filename
           Jehu struktura je:
                <regularny vyraz>\t*<zoznam format. parametrov>
                -formatovacie parametre su oddelene ciarkami 
                a lubovolnym poctom medzier a \t

    @param list - nacitany sobur po riadoch
    @return list - vrati list v ktorom polozky su hash
                   hash ma kluc regularny vyraz a polozku
                   list s dvoma polozkamy: 
                        Prva co sa ma pridat pri najdeny regularu na zaciatok
                        Druhy co sa ma pridat na koniec.
    '''
    parsed = [];

    #prelistuje po riadkoch data z --format=file
    for line in format_data:
        #oddeli <RV> od <zoznamu_formatovacich parametrov>
        #medzi RV a zoznamom_parametrom.. je oddelovac \t
        #split vrati list

        #odstranienie ukoncovaca riadku
        pattern = re.compile("\n");
        if (pattern.search(line) != None):
            line = line[0:len(line) - 1];


        line_parsed = line.split('\t');
        rv = line_parsed[0];
        if (len(line_parsed) < 2):
            error_exit(RET_BAD_FORMAT_FILE,
                    "Chyba: subor --format obsahuje nevalidne data!\n");
        
        format_params = [];

        #rozparsovanie prveho formatovacieho prikazu
        line_parsed = line.split(',');
        #v prvom je ulozeny aj rv - rv treba odstranit
        first = line_parsed[0];
        first = first.split('\t');
        if (len(first) < 2):
            error_exit(RET_BAD_FORMAT_FILE,
                    "Chyba: subor --format obsahuje nevalidne data!\n");
        #odstrani prazdne - ked bolo zadanych viac tabulatorov medzi rv bold
        first = [x for x in first if x];
        #print(first);
        #prvy formatovaci prikaz je v liste na druhej pozicii
        first = first[1:];
        if (len(first) != 1):
            error_exit(RET_BAD_FORMAT_FILE,
                    "Chyba: subor --format obsahuje nevalidne data!\n");
        
        first = first[0];
        first = first.replace(" ", "");
        format_params.append(first);

        #rozparsovanie ostatnych formatovacich prikazov
        line_parsed = line.split(',');
        line_parsed = line_parsed[1:];
        for item in line_parsed:
            pattern = re.compile("\w+\s+\w+");
            if (pattern.search(item) != None):
                error_exit(RET_BAD_FORMAT_FILE,
                        "Chyba: subor --format obsahuje nevalidne data!\n");
            item = item.replace(" ", "");
            item = item.replace("\t", "");

            #ak je definovany pridam k formatovacim prikazom
            #inaksie je prazdny a je to chyba
            if (item):
                format_params.append(item);
            else:
                error_exit(RET_BAD_FORMAT_FILE,
                        "Chyba: subor --format obsahuje nevalidne data!\n");

        #print(format_params);

        #prelistovanie formatovacich parametrov - kontrola
        params_list = [];
        start = "";
        end = "";
        for param in format_params:
            if (((param in FORMAT_PARAMS) == False) and 
                (re.search("^size:[1-7]$" , param) == None) and
                (re.search("^color:[ABCDEF0-9]{6}$", param) == None)):
                    error_exit(RET_BAD_FORMAT_FILE, 
                  "Chyba: subor --format=filename obsahuje nevalidne data!\n");
 
            if (param == "bold"):
                start = start + "<b>";
                end = "</b>" + end;
            if (param == "italic"):
                start = start + "<i>";
                end = "</i>" + end;
            if (param == "underline"):
                start = start + "<u>";
                end = "</u>" + end;
            if (param == "teletype"):
                start = start + "<tt>";
                end = "</tt>" + end;
            if (re.search("^size:[1-7]$", param) != None):
                #vyparsovanie cisla
                pattern = re.compile("[1-7]");
                obj = pattern.search(param);
                start = start + "<font size=" + \
                        param[obj.start():obj.end()] + ">";
                end = "</font>" + end;
            if (re.search("^color:[ABCDEF0-9]{6}$", param) != None):
                #vyparsovanie cisla
                pattern = re.compile("[ABCDEF0-9]{1,6}");
                obj = pattern.search(param);
                start = start + "<font color=#" + \
                        param[obj.start():obj.end()] + ">";
                end = "</font>" + end;

        #v hash je kluc a list
        #prva polozka listu je zaciatocny formatovaci retazec, druha konecny
        params_list.append(start);
        params_list.append(end);
            
        if (control_rv(rv) != True):
            error_exit(RET_BAD_FORMAT_FILE, "Chyba: nespravy regularny vyraz!\n");
        else:
            #uprava RV pre python
            rv = rv_modification(rv);
        
        hash_item = {rv : params_list};
        parsed.append(hash_item);
    
    return parsed;

def search_patterns(list_pattern, string):
    '''
    @brief Funkcia prejde zoznam list_pattern z kazneho prvku
           urobi RV ktory sa vyhlada v stringu, ak sa najde vrati True

    @param list - regularnych vyrazov
    @param string - v ktorom sa bude hladat
    @return bool - ak najde true inak false
    '''

    for item in list_pattern:
        #pred polozkou nesmie byt %
        item = re.escape(item);
        # druha cast je tam koli tomu ze moze byt na zaciatku retazca
        pattern = re.compile("([^%]{1}"+item+")|(^"+item+")");
        obj = pattern.search(string);
        if (obj != None):
            return True;

    return False;

def parenthesis_control(string):
    '''
    @brief skontroluje zatvorky, ci nejaka nieje otvorena

    @param string - string kde mozu byt zatvorky
    @return bool - true ak su zatvorky v stringu v poriadku, inak false
    '''
    length = len(string);
    index = 0;

    list_brackets = "";

    while (index < length):
        if (index == 0):
            if (string[index] == '('):
                list_brackets.append('(');
            elif (string[index] == ')'):
                if (len(list_brackets) == 0):
                    return False;
                list_brackets.pop();
        else:
            if (string[index] == '(' and string[index - 1] != '%'):
                list_brackets.append('(');
            elif (string[index] == ')' and string[index - 1] != '%'):
                if (len(list_brackets) == 0):
                    return False;
                list_brackets.pop();
        
        index = index + 1;

    if (len(list_brackets) == 0):
        return True;

    return False;

def control_rv(rv):
    '''
    @brief Funkcia skontroluje ci RV zo suboru --fortmat=filename
           je zadany spravne.

    @param regularny vyraz zo zadania
    @return true ak je validny, inak false
    '''
    length = len(rv);

    #ak je dlzka RV jeden znak
    if (length == 1):
        pattern = re.compile("[\!\.\+\*\|\(\)\%]");
        if (pattern.search(rv) != None):
            return False;

    #kontrola prvych - prve nemoze byt . | + * )
    if (rv[0] == '.' or rv[0] == '|' or rv[0] == '+' or
        rv[0] == '*' or rv[0] == ')'):
        return False;
    

    #kontrola poslednych - posledne nemoze byt . ! ( % |
 #   if ((rv[length - 1] == '.' or rv[length - 1] == '!' or 
 #       rv[length - 1] == '(' or rv[length - 1] == '|' or
 #       rv[length - 1 == '%']) and
 #       (length >= 2 and rv[length - 2 ] != '%')):
 #       print("ssa", rv[length - 1]);
 #       return False;

    if (length >= 2 and rv[length - 2] != "%"):
        if (rv[length - 1] == '.' or rv[length - 1] == '!' or 
            rv[length - 1] == '(' or rv[length - 1] == '|' or
            rv[length - 1] == '%'):
            return False;

    #kontrola rovnakych znakov za sebou - nesmu ist .. || ** ++ !!
    if (search_patterns(['..', '||', '**', '++', '!!' ], 
        rv) == True):
        return False;

    #kat 1: !* !+ !. !| !( !)
    #kontrola dvojznakov kategoria 1. nesmie !* !+ !. !| !( !)
    if (search_patterns(['!*', '!+', '!.', '!|', '!(', '!)'], rv) == True):
        return False;
    
    #kat 2: *! *| *. *+ *( *)
    #kontrola dvojznakov kategoria 2. nesmie *+ TODO *| *. forum opytat
    if (search_patterns(['*+'], rv) == True):
        return False;

    #kat 3: +! +* +| +. +( +)
    #kontrola dvojznakov kategoria 3. nesmie +* TODO +| +. forum opytat 
    if (search_patterns(['+*'], rv) == True):
        return False;

    #kat 4: .! .* .+ .| .( .) 
    #kontrola dvojznakov kategoria 4. nesmie .+ .*  TODO  .| (.!-toto asi moze) 
    if (search_patterns(['.+', '.*', '.|', '.)'], rv) == True):
        return False;

    #kat 5: |! |* |+ |. |( |) 
    #kontrola dvojznakov kategoria 5. nesmie |* |+ TODO |. forum opytat 
    if (search_patterns(['|*', '|+', '|.', '|)'], rv) == True):
        return False;

    #kat 6: (. (| (! (+ (* ()
    #kontrola dvojznakov kategoria 6. nesmie (. (+ (*
    if (search_patterns(['(.', '(+', '(*', '()', '(|'], rv) == True):
        return False;

    #kat 7: ). )| )! )* )+ )(
    #if (search_patterns( ,rv) == True):
     #   return False;

    #kontrola ci %[sadlLwWtn.|!*+()%]
    pattern = re.compile("%[^sadlLwWtn\.\|\!\*\+\(\)\%]");
    if (pattern.search(rv) != None):
        return False;

    return True;

def rv_modification(rv):
    '''
    @brief Funkcia upravy regularny vyraz pre python
           Najprv vyescapuje vsetky znaky
           potom odescapuje znaky co su z hodne z IPP RV
           potom sa RV upravuje podla zadania

    @param string  regularny vyraz
    @return string upraveny regularny vyraz
    '''
    #print("rv povodny = ", rv);

    #vyescapovanie pythonovkych znakov
    rv = re.escape(rv);    
    #spatne odescapovanie niektorych znakov
    # | * + ( ) 
    rv = rv.replace("\|", "|");
    rv = rv.replace("\*", "*");
    rv = rv.replace("\+", "+");
    rv = rv.replace("\(", "(");
    rv = rv.replace("\)", ")");

    #odstrananie bodky
    pattern = re.compile("[^%]\\\\\.");
    obj = pattern.search(rv);
    while(obj != None):
        rv = list(rv);
        rv[obj.start() + 1] = "";
        rv[obj.start() + 2] = "";

        rv = "".join(rv);
        obj = pattern.search(rv);
    
    #uprava !A za [^A]
    pattern = re.compile("(\\\\\%\\\\\%\\\\\!)|([^%]\\\\\!)|(^\\\\\!)");
    index = 0;
    obj = pattern.search(rv, index);
    while (obj != None):
        rv = list(rv);

        if (obj.group(1)):
            #nasiel \%\%\!
            rv[obj.start() + 4] = "";
            rv[obj.start() + 5] = "[^";
        elif(obj.group(2)):
            #nasiel a\!
            rv[obj.start() + 1] = "";
            rv[obj.start() + 2] = "[^";
        else:
            #nasiel \!a
            rv[obj.start()] = "";
            rv[obj.start() + 1] = "[^";


        #ak je nieco vyescapovane musi sa posunut o 2 znaky
        if (rv[obj.end()] == "\\"):
            if (len(rv) > obj.end() + 1 and rv[obj.end() + 1] == "%"):
                rv[obj.end() + 2] = rv[obj.end() + 2] + "]";
            else:
                rv[obj.end() + 1] = rv[obj.end() + 1] + "]";
        else:
            rv[obj.end()] = rv[obj.end()] + "]";

        rv = "".join(rv);
        index = obj.end();
        obj = pattern.search(rv, index);
    
    #specialne znaky %
    # %s = \s znaky \t\n\r\f\v
    rv = rv.replace("\%s", "\s");
    # %a = . jeden lubovolny znak
    rv = rv.replace("\%a", ".");
    # %d = \d cisla od 0 do 9
    rv = rv.replace("\%d", "\d");
    # %l = [a-z] male pismena od a do z
    rv = rv.replace("\%l", "[a-z]");
    # %L = [A-Z] velka pismena od A do Z
    rv = rv.replace("\%L", "[A-Z]");
    # %w = [a-zA-Z] male a velke pismena (%l%L)
    rv = rv.replace("\%w", "[a-zA-Z]");
    # %W = [0-9a-zA-Z] cisla a male a velke pismena
    rv = rv.replace("\%W", "[0-9a-zA-Z]");
    # %t = \t 
    rv = rv.replace("\%t", "\t");
    # %n = znak \n 
    rv = rv.replace("\%n", "\n");
    
    #specialne znaky . | ! * + ( ) % 
    #pozor | * + ( ) nie su escapovane
    rv = rv.replace("\%\.", "\.");
    rv = rv.replace("\%|", "\|" );
    rv = rv.replace("\%\!", "\!" );
    rv = rv.replace("\%*", "\*");
    rv = rv.replace("\%+", "\+");
    rv = rv.replace("\%(", "\(");
    rv = rv.replace("\%)", "\)");
    rv = rv.replace("\%\%", "\%");

    return rv;

#####################################################################
#                       Zaciatok skriptu
#####################################################################

#spracovanie parametrov
params_list = params();

data = "";
format_list = "";

if ("--help" in params_list):
    if (len(params_list) == 1):
        print_help();
    else :
        error_exit(RET_BAD_PARAMS, 
                  "Chybne parametre: parameter --help sa nesmie kombinovat\n");

#################################################
#                   Otvaranie suborov
#otvorenie suboru na citanie dat
if ("--input" in params_list):
    #subor
    try:
        file_in = open(params_list[params_list.index("--input") + 1], mode = 'r', 
                       encoding = 'utf-8');
        data = file_in.read();
        file_in.close();
    except:
        error_exit(RET_BAD_IN_FILE, "Chyba: pri otvarani vstupneho suboru!\n");
else:
    #stdin
    try: 
        file_in = open(sys.stdin.fileno(), mode = 'r', encoding = 'utf-8',
                closefd = False);
        data = file_in.read();
    except:
        error_exit(RET_BAD_IN_FILE,
                   "Chyba: pri otvarani vstupneho suboru - STDIN!\n");

data_length = len(data);
index_hash = {};

#otvorenie formatovacieho suboru
if ("--format" in params_list):
    try:
        file_format = open(params_list[params_list.index("--format") + 1], mode = 'r', 
                       encoding = 'utf-8');
        format_data = file_format.readlines();
        file_format.close();

        #rozparsovanie --format suboru
        format_list = parse_format_file(format_data);

        #Ziskanie indexov na vkladanie znaciek
        for hashes in format_list:
            for rv, value in hashes.items():
                # hladanie podla regularu v hash
                index = 0;
                pattern = re.compile(rv, re.DOTALL);
                obj = pattern.search(data, index);
                stop = re.compile('\[\^\.\]');
                obj_stop = stop.search(rv);
                if (obj_stop != None):
                    continue;
                while (obj != None):
                    start = obj.start();
                    end = obj.end();

                    #print(rv, " ,index = ", index, " ,length = ", data_length);
                    #print(rv," ,start = ", start, " end = ", end);

                    #ochrana proti prazdnemu retazcu
                    if (start == end):
                        index = index + 1; #musi byt +1 inak najde to iste
                        obj = pattern.search(data, index);
                        #prazdne retazce to zabije
                        if (index == data_length):
                            break;
                        continue;

                    if (start in index_hash):
                        index_hash[start] = index_hash[start]+value[0];
                    else:
                        index_hash[start] = value[0];

                    if (end in index_hash):
                        index_hash[end] = value[1]+index_hash[end];
                    else:
                        index_hash[end] = value[1];
               
                    index = end ; #musi byt +1 inak najde to iste
                    if (end == data_length):
                        break;
                    obj = pattern.search(data, index);
    except IOError:
        error_exit(RET_BAD_IN_FILE, 
                "Chyba: pri otvarani vstupneho suboru! --format\n");
    except re.error:
        error_exit(RET_BAD_FORMAT_FILE, 
                   "Chyba: nevalidny regularny vyraz!\n");

#prejdenie hash tabulky a pridanie formatovacich retazcov do textu - data
#musi sa prejst od najvacsieho indexu
#pretoze do suboru sa musi pridavat od konca
keys = list(index_hash);
keys.sort();
index_keys = len(keys) - 1;
data = list(data);
while (index_keys >= 0):
    key = keys[index_keys];

    #ak sa ma ulozit nieco na koniec suboru
    #pouzije sa metoda append
    if (key == data_length):
        data.append(index_hash[key]);
    else:
        data[key] = index_hash[key] + data[key];
    index_keys = index_keys - 1;

data = "".join(data);

#prida <br /> na koniec kazdeho riadka
if ("--br" in params_list):
    pattern = re.compile("\r\n");
    obj = pattern.search(data);
    if (obj == None):
        pattern = re.compile("\n");

    #pridavenie <br />
    index = 0;
    obj = pattern.search(data, index);
    while (obj != None):
        data = list(data);
        data[obj.start()] = "<br />" + data[obj.start()];
        data = "".join(data);
        index = obj.end() + len("<br />"); 
        obj = pattern.search(data, index);

#otvorenie vystupu na zapisovanie dat
if ("--output" in params_list):
    try:
        file_out = open(params_list[params_list.index("--output") + 1], mode = 'w', 
                       encoding = 'utf-8');
        file_out.write(data);
        file_out.close();
    except:
        error_exit(RET_BAD_OUT_FILE, "Chyba: pri otvarani vystupneho suboru!\n");
else:
    try: 
        file_out = open(sys.stdout.fileno(), mode = 'w', encoding = 'utf-8',
                closefd = False);
        file_out.write(data);
    except:
        error_exit(RET_BAD_OUT_FILE,
                   "Chyba: pri otvarani vystupneho suboru - STDOUT!\n");

sys.exit(RET_OK);

