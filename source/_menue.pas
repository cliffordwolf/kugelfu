UNIT _Menue;

INTERFACE

 USES Crt,Mode_X,KF_Objects,Vektorball,KF_Tools,SB_SND;

 TYPE _SND_Config = record
       usesb : boolean;
       adr : word;
       irq,dma : byte;
      end;

 PROCEDURE Menue;

 PROCEDURE Config_Menue;

 PROCEDURE SHARE_INDIC;

 PROCEDURE KillerDemMenue(f1,f2 : byte);

 PROCEDURE ShareEnd;

 CONST Ende : boolean = false;
       Demo : boolean = true;
       pl1 : byte = 4;
       pl2 : byte = 2;

 VAR   SND_Config : _snd_config;
       fx_klick : _sample;
       demost : ^boolean;

IMPLEMENTATION

 CONST Fighter : array [1..7] of string =
        ('KEYBOARD LEFT',
        'KEYBOARD RIGHT',
        'MR. DRUNKEN',
        'MR. TIPSY',
        'MR. DULL',
        'MR. BRUTAL',
        'MR. KILLER');

       Indication : array [1..11] of string =
        ('DIESES 2 - FIGHTER - DEMO VON',
         'KUGELFU',
         'ZEIGT IHNEN NUR 2 VON 5',
         'INTELLIGENTEN COMPUTERGEGNERN!',
         '',
         'BESTELLEN SIE HEUTE NOCH',
         'DIE VOLLVERSION!',
         '',
         'ADRESSE:   MICHAEL WOLF JUN.  ',
         '           FOEHRENGASSE 16    ',
         '           A-2333 LEOPOLDSDORF');

       EndText : array [1..21] of string =
        ('',
         'Dieses 2 - Kaempfer - Demo von',
         'KUGELFU',
         'zeigt ihnen nur 2 von 5 intelligenten',
         'Computergegnern!',
         '',
         'Ueberzeugen Sie sich selbst von dem Koennen',
         'des beinahe unbezwingbaren MR. Killer',
         'indem Sie das Spiel mit',
         'KUGELFU KILLER',
         'oder mit',
         'KUGELFU KILLTIPSY',
         'starten!',
         '',
         'Bestellen Sie noch heute die Vollversion von KUGELFU, indem Sie',
         'das Bestellformular (Datei BESTELL.TXT) an mich schicken.',
         'Bezahlt wird per Nachnahme (Preis: S 130,- / DM 19,-).',
         '',
         'Ausgefuelltes Formular an: Michael Wolf jun.     ',
         '                           Foehrengasse 16       ',
         '                           A-2333 Leopoldsdorf   ');

 VAR TXT_Skal : real;
     TXT_Abst : word;

 PROCEDURE ShareEnd;
  var z1 : byte;
  begin
   textmode(3);
   clrscr;
   for z1 := 1 to 21 do
   begin
    gotoxy(40-(length(endtext[z1]) div 2),z1);
    write(endtext[z1]);
   end;
   writeln;
   writeln;
   writeln;
 end;

 FUNCTION GetInput : char;
  var ch : char;
  begin
   screen_on;
   ch := readkey;
   if ord(ch) = 0 then
   begin
    ch := readkey;
    case ord(ch) of
     72 : ch := '8';
     75 : ch := '4';
     77 : ch := '6';
     80 : ch := '2';
     else ch := '~';
    end;
   end;
   if ch = chr(13) then ch := ' ';
   getinput := ch;
   while keypressed do readkey;
 end;

 PROCEDURE Drawscreen;
  begin
   screen_off;
   init_modex;
   getpal;
   palette[0] := 0;
   palette[1] := 0;
   palette[2] := 0;
   setpal;
   setballcol(0,63,63,40,1);
   setballcol(1,63,31,0,1);
   setballcol(2,30,63,30,1);
   setballcol(3,30,20,40,1);
   setballcol(4,20,40,40,1);
   setballcol(5,30,30,30,1);
   delvpage;
   switch;
   waitretrace;
   delvpage;
 end;

 PROCEDURE Kasten(nr,col : byte);
  var z1 : word;
  begin
   for z1 := 0 to 319 do
   begin
    putpixel(z1,20*nr-19,col);
    putpixel(z1,20*nr-1,col);
   end;
   for z1 := 1 to 19 do
   begin
    putpixel(0,20*nr-z1,col);
    putpixel(319,20*nr-z1,col);
   end;
 end;

 PROCEDURE Wrline(nr,col : byte; str : string);
  var cs : vekball;
      vs : _vbstring;
  begin
   cs.init(0,0,319,199,160,100,256);
   vs.init;
   vs.text := str;
   vs.color := col;
   vs.put2cs(0,(txt_abst*(nr-1))-100+round(10*txt_skal)+round((20*(nr-1))*txt_skal),0,txt_skal,cs);
   cs.draw;
   vs.done;
   cs.del;
 end;

 PROCEDURE SHARE_INDIC;
  var z1 : byte;
  begin
   drawscreen;
   txt_skal := 0.5;
   txt_abst := 3;
   delvpage;
   wrline(1,2,'SHAREWARE INDICATION');
   for z1 := 1 to 11 do
    if z1 in [6,7] then wrline(z1+2,2,indication[z1])
     else wrline(z1+2,3,indication[z1]);
   txt_skal := 1;
   txt_abst := 0;
   wrline(10,5,'OK');
   kasten(10,1);
   switch;
   waitretrace;
   wiedergabe(fx_klick);
   while keypressed do readkey;
   getinput;
 end;

 PROCEDURE KillerDemMenue(f1,f2 : byte);
  begin
   drawscreen;
   delvpage;
   wrline(1,2,'SHOW');
   wrline(3,1,fighter[f1]);
   wrline(4,5,'VS');
   wrline(5,4,fighter[f2]);
   wrline(10,5,'FIGHT');
   kasten(10,1);
   switch;
   waitretrace;
   getinput;
 end;

 PROCEDURE SelectPl(pl : byte);
  var mp : byte;
      ch : char;
      col : byte;
      z1 : byte;
  begin
   if pl = 1 then mp := pl1 else mp := pl2;
   col := (pl-1)*3+1;
   repeat
    delvpage;
    if pl = 1 then wrline(1,2,'SELECT PLAYER 1')
     else wrline(1,2,'SELECT PLAYER 2');
    for z1 := 1 to 7 do
     wrline(2+z1,col,fighter[z1]);
    kasten(mp+2,1);
    switch;
    waitretrace;
    wiedergabe(fx_klick);
    ch := getinput;
    case ch of
     '8' : if mp > 1 then dec(mp);
     '2' : if mp < 7 then inc(mp);
    end;
    if (mp in [5..7]) and demo and (ch = ' ') then
    begin
     share_indic;
     ch := '~';
    end;
    if pl = 2 then z1 := pl1 else z1 := pl2;
    if (z1 = mp) and (mp in [1,2]) and (ch = ' ') then
    begin
     if mp = 1 then z1 := 2 else z1 := 1;
     if pl = 2 then pl1 := z1 else pl2 := z1;
    end;
   until ch = ' ';
   if pl = 1 then pl1 := mp else pl2 := mp;
 end;

 PROCEDURE Main;
  var mp : byte;
      ch : char;
  begin
   mp := 3;
   repeat
    delvpage;
    wrline(1,2,'MAIN MENUE');
    wrline(3,1,fighter[pl1]);
    wrline(4,5,'VS');
    wrline(5,4,fighter[pl2]);
    wrline(7,5,'SELECT PLAYER 1');
    wrline(8,5,'SELECT PLAYER 2');
    wrline(9,5,'START GAME');
    wrline(10,5,'QUIT TO DOS');
    kasten(mp+6,1);
    switch;
    waitretrace;
    wiedergabe(fx_klick);
    ch := getinput;
    case ch of
     '8' : if mp > 1 then dec(mp);
     '2' : if mp < 4 then inc(mp);
     ' ' : case mp of
            1 : SelectPl(1);
            2 : SelectPl(2);
            4 : ende := true;
           end;
    end;
   until (mp in [3,4]) and (ch = ' ');
 end;

 PROCEDURE Menue;
  var ch : char;
  begin
   txt_skal := 1;
   txt_abst := 0;
   drawscreen;
   Main;
   textmode(3);
 end;

 PROCEDURE CONFIG_SB;
  var mp : byte;
      ch : char;
  begin
   mp := 1;
   repeat
    delvpage;
    wrline(1,2,'SOUND - OPTIONS');
    wrline(3,5,'NO SOUND');
    wrline(4,5,'SOUND BLASTER');
    kasten(mp+2,1);
    switch;
    waitretrace;
    ch := getinput;
    case ch of
     '8' : if mp > 1 then dec(mp);
     '2' : if mp < 2 then inc(mp);
    end;
   until ch = ' ';
   with snd_config do
   if mp = 2 then usesb := true else usesb := false;
   if mp = 1 then exit;
   mp := 1;
   repeat
    delvpage;
    wrline(1,2,'SOUND - OPTIONS');
    wrline(2,2,'SB - PORT');
    wrline(4,5,'220H');
    wrline(5,5,'240H');
    wrline(6,5,'260H');
    wrline(7,5,'280H');
    kasten(mp+3,1);
    switch;
    waitretrace;
    ch := getinput;
    case ch of
     '8' : if mp > 1 then dec(mp);
     '2' : if mp < 4 then inc(mp);
    end;
   until ch = ' ';
   with snd_config do
   case mp of
    1 : adr := $220;
    2 : adr := $240;
    3 : adr := $260;
    4 : adr := $280;
   end;
   mp := 1;
   repeat
    delvpage;
    wrline(1,2,'SOUND - OPTIONS');
    wrline(2,2,'SB - DMA');
    wrline(4,5,'1');
    wrline(5,5,'3');
    wrline(6,5,'5');
    wrline(7,5,'7');
    kasten(mp+3,1);
    switch;
    waitretrace;
    ch := getinput;
    case ch of
     '8' : if mp > 1 then dec(mp);
     '2' : if mp < 4 then inc(mp);
    end;
   until ch = ' ';
   with snd_config do
   case mp of
    1 : dma := 1;
    2 : dma := 3;
    3 : dma := 5;
    4 : dma := 7;
   end;
   mp := 3;
   repeat
    delvpage;
    wrline(1,2,'SOUND - OPTIONS');
    wrline(2,2,'SB - IRQ');
    wrline(4,5,'1');
    wrline(5,5,'3');
    wrline(6,5,'5');
    wrline(7,5,'7');
    wrline(8,5,'11');
    wrline(9,5,'12');
    wrline(10,5,'15');
    kasten(mp+3,1);
    switch;
    waitretrace;
    ch := getinput;
    case ch of
     '8' : if mp > 1 then dec(mp);
     '2' : if mp < 7 then inc(mp);
    end;
   until ch = ' ';
   with snd_config do
   case mp of
    1 : irq := 1;
    2 : irq := 3;
    3 : irq := 5;
    4 : irq := 7;
    5 : irq := 11;
    6 : irq := 12;
    7 : irq := 15;
   end;
 end;

 PROCEDURE SB_Main;
  var mp : byte;
      ch : char;
      h1 : string;
  begin
   mp := 1;
   repeat
    delvpage;
    wrline(1,2,'SOUND - OPTIONS');
    if not snd_config.usesb then wrline(3,3,'NO SOUND')
    else with snd_config do
    begin
     wrline(3,3,'SOUND BLASTER');
     case adr of
      $220 : h1 := '220h';
      $240 : h1 := '240h';
      $260 : h1 := '260h';
      $280 : h1 := '280h';
      else str(adr,h1);
     end;
     h1 := 'PORT '+h1;
     wrline(4,3,h1);
     str(dma,h1);
     h1 := 'DMA '+h1;
     wrline(5,3,h1);
     str(irq,h1);
     h1 := 'IRQ '+h1;
     wrline(6,3,h1);
    end;
    wrline(8,5,'CORRECT');
    wrline(9,5,'NOT CORRECT');
    kasten(mp+7,1);
    switch;
    waitretrace;
    ch := getinput;
    case ch of
     '8' : if mp > 1 then dec(mp);
     '2' : if mp < 2 then inc(mp);
     ' ' : if mp = 2 then config_sb;
    end;
   until (ch = ' ') and (mp = 1);
 end;

 PROCEDURE Config_Menue;
  var f : file;
  begin
   txt_skal := 1;
   txt_abst := 0;
   with snd_config do
   begin
    usesb := true;
    adr := $220;
    dma := 1;
    irq := 7;
   end;
   {$I-}
    assign(f,'config.dat');
    reset(f,1);
   {$I+}
   if ioresult = 0 then
   begin
    blockread(f,snd_config,sizeof(snd_config));
    close(f);
   end;
   drawscreen;
   sb_main;
   {$I-}
    assign(f,'config.dat');
    rewrite(f,1);
   {$I+}
   if ioresult = 0 then
   begin
    blockwrite(f,snd_config,sizeof(snd_config));
    close(f);
   end;
   textmode(3);
 end;

 BEGIN
END.