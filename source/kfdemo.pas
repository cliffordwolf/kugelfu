{
  Žnderrungen fuer Demo <> Vollversion:
     2 Interrupts
     2 Zuweisungen - Demo
     1 Zuweisung - Demost^
}

PROGRAM KUGELFU;

 USES _Fight,SB_SND,KF_Objects,_Menue,Vektorball,KF_Tools,Crt,_Ident,DOS;

 CONST EXTRACODE = 'EISIG';
       Killerdem1 : boolean = false;
       Killerdem2 : boolean = false;
       checkit : boolean = false;
       freiint1 = $60;
       freiint2 = $61;
       timerint = $1c;
       keybint = 9;
       
 var h1,h2 : byte;
     h3,h4 : string;
     usesb : boolean;
     err : integer;
     ch : char;
     v1,v2 : pointer;

procedure newtimer; interrupt;
 begin
   asm
    int freiint1;
   end;
   demo := true;
end;

procedure newkey; interrupt;
 begin
   asm
    int freiint2;
   end;
   demo := true;
end;

 BEGIN
  writeln;
  h3 := paramstr(0);
  delete(h3,1,length(h3)-11);
  if h3 <> 'KUGELFU.EXE' then halt(3);
  new(demost);
  getintvec(timerint,v1);
  setintvec(freiint1,v1);
  setintvec(timerint,@newtimer);
  getintvec(keybint,v2);
  setintvec(freiint2,v2);
  setintvec(keybint,@newkey);
  {demo := false;} {DEMO oder VOLLVERSION ?}
  if demo then
  begin
   writeln('KUGELFU - Demoversion');
   writeln('Entwickelt von Michael Wolf im Jahre 1995');
   writeln('Dieses Programm darf Vervielfaeltigt, Verbreitet');
   writeln('und ueber Telekomunikationssysteme gesendet werden.');
   writeln('Alle weitere Rechte bleiben vorbehalten.');
  end else
  begin
   writeln('KUGELFU - Vollversion');
   writeln('Entwickelt von Michael Wolf im Jahre 1995');
   writeln('Alle Rechte bleiben vorbehalten.');
  end;
  ident_lade('Ident.dat');
  if not ident_teste('kugelfu.exe') then
  begin
   writeln;
   writeln('    !!! Programm fehlerhaft !!!');
   writeln;
   halt;
  end;
  demost^ := true;
  writeln;
  repeat
   write('Geschwindigkeit (0-schnell bis 15-langsam)? ');
   readln(h3);
   val(h3,h1,err);
  until (err = 0) and (h1 in [0..15]);
  waithun := h1;
  if paramcount > 0 then
   for h1 := 1 to paramcount do
   begin
    h3 := '';
    h4 := paramstr(h1);
    for h2 := 1 to length(h4) do
     h3 := h3+upcase(h4[h2]);
    if h3 = extracode then extras := true;
    if h3 = 'KILLER' then killerdem1 := true;
    if h3 = 'KILLTIPSY' then killerdem2 := true;
    if h3 = 'CHECKIT' then checkit := true;
  end;
  writeln;
  if killerdem1 and killerdem2 then
  begin
   writeln('Sie koennen entweder die Option');
   writeln(' KILLER (MR. KILLER  VS  MR. KILLER)');
   writeln('oder');
   writeln(' KILLTIPSY (MR. TIPSY  VS  MR. KILLER)');
   writeln('benutzen; nicht aber beide Optionen gleichzeitig!');
   writeln;
   halt;
  end;
  if killerdem1 then writeln('Demo: MR. KILLER  VS  MR. KILLER');
  if killerdem2 then writeln('Demo: MR. TIPSY  VS  MR. KILLER');
  preplists;
  loadmask('data\kugel.map');
  load_chars('data\vektchar.dat');
  if checkit then usesb := true
   else config_menue;
  with snd_config do
  if usesb then
  begin
    if not checkit then init_sb(irq,dma,adr);
    loadwav('data\treffer1.wav',fx_treffer);
    loadwav('data\vorbei1.wav',fx_vorbei);
    loadwav('data\flatter1.wav',fx_flatter);
    loadwav('data\beam1.wav',fx_beam);
    loadwav('data\klick1.wav',fx_klick);
    loadwav('data\bkick1.wav',fx_bkick);
  end;
  if checkit then
  with identblock do
  begin
   writeln;
   writeln(' Die Option Checkit ueberprueft die lauffaehigkeit des Programms!');
   writeln;
   writeln('Registrierung:');
   writeln;
   writeln(' Username: ',username);
   writeln('      Nr.: ',usernumber);
   writeln;
   writeln;
  end
  else if killerdem1 then
  begin
   killerdemmenue(7,7);
   fight(7,7);
  end
  else if killerdem2 then
  begin
   killerdemmenue(4,7);
   fight(4,7);
  end
  else
  begin
   ident_lade('Ident.dat');
   repeat
    if ident_teste('kugelfu.exe') and (demost^ = demo) then
    begin
     menue;
     if not ende then fight(pl1,pl2);
     if demo and (not ende) then share_indic;
    end else ende := true;
    demo := true;
   until ende;
  end;
  wiedergabe(fx_klick);
  if not checkit then
  begin
   if demo then share_indic;
   textmode(3);
   if demo then shareend
   else with identblock do
   begin
    clrscr;
    writeln;
    writeln('KUGELFU - Vollversion');
    writeln('Entwickelt von Michael Wolf im Jahre 1995.');
    writeln('Alle Rechte bleiben vorbehalten.');
    writeln;
    writeln('Registrierung:');
    writeln;
    writeln(' Username: ',username);
    writeln('      Nr.: ',usernumber);
    writeln;
    writeln;
   end;
   {writeln('Maximale Geschwindigkeit bei Ihrem Rechner: ',round(speedsum/speedanz));}
   {writeln(speedsum,'/',speedanz,'=',round(speedsum/speedanz));}
   case random(3) of
    0 : wiedergabe(fx_beam);
    1 : wiedergabe(fx_bkick);
    2 : wiedergabe(fx_flatter);
   end;
   if snd_config.usesb then
   begin
    repeat until sbready;
    done_sb;
   end;
  end;
  setintvec(timerint,v1);
  setintvec(keybint,v2);
END.