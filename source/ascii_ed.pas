PROGRAM ASCII_Edit;

 USES Crt;

 TYPE _ChMap = record
       map : array [0..7] of byte;
       yver : integer;
      end;

 CONST ende : boolean = false;
       fname = 'vektchar.dat';

 VAR mx,my,mbott : byte;
     fdata : array [0..255] of _chmap;
     aktchar : array [1..8,1..8] of boolean;
     aktnum : byte;
     aktyver : integer;


 PROCEDURE Maus_an; assembler;
  asm
   mov	ax,1
   int	33h
 end;

 PROCEDURE Maus_aus; assembler;
  asm
   mov ax,2
   int 33h
 end;

 PROCEDURE Maus_Status(var x,y,knopf : byte); assembler;
  asm
   mov ax,3
   int 33h
   shr cx,3
   shr dx,3
   inc cx
   inc dx
   les di,x
   mov es:[di],cl
   les di,y
   mov es:[di],dl
   les di,knopf
   mov es:[di],bl
 end;

 PROCEDURE DrawInfo;
  var z1,z2 : byte;
  begin
   maus_aus;
   for z1 := 1 to 8 do
   for z2 := 1 to 8 do
   begin
    gotoxy((z1-1)*4+3,z2*2);
    if aktchar[z1,z2] then write('@')
     else write(' ');
   end;
   gotoxy(23,23);
   if aktnum <> 7 then write('Û Û');
   gotoxy(24,23);
   if aktnum <> 7 then write(chr(aktnum));
   if aktnum = 7 then
   begin
    gotoxy(23,23);
    write('Pip');
   end;
   gotoxy(5,23);
   write('           ');
   gotoxy(5,23);
   write('(Num. ',aktnum,')');
   maus_an;
 end;

 PROCEDURE DrawScreen;
  var z1,z2 : integer;
  begin
   maus_aus;
   clrscr;
   for z2 := 1 to 8 do
   begin
    for z1 := 1 to 8 do write('----'); writeln('-');
    for z1 := 1 to 8 do write('|   '); writeln('|');
   end;
   for z1 := 1 to 33 do write('-'); writeln;
   gotoxy(40,2);
   write('|  SET  |');
   gotoxy(40,4);
   write('| RESET |');
   gotoxy(5,20);
   write('| EXIT |   | LOAD |   | SAVE |');
   gotoxy(23,22);
   write('ÜÜÜ');
   gotoxy(23,24);
   write('ßßß');
   gotoxy(5,22);
   write('Originalzeichen:');
   gotoxy(5,24);
   write('| ',chr(17),' |   | ',chr(16),' |');
   aktnum := 0;
   maus_an;
   drawinfo;
 end;

 PROCEDURE Menue;
  var h1,h2 : integer;
      h3 : string;
  function inbott(x1,y1,x2,y2 : byte) : boolean;
   begin
    inbott := true;
    if (x1 > mx) or (y1 > my) then inbott := false;
    if (x2 < mx) or (y2 < my) then inbott := false;
    if mbott = 0 then inbott := false;
  end;
  procedure setch;
   var z1,z2 : integer;
       h1 : byte;
   begin
    for z1 := 0 to 7 do
    begin
     h1 := 0;
     for z2 := 0 to 7 do
      if aktchar[z2+1,z1+1] then h1 := h1 + 1 shl z2;
     fdata[aktnum].map[z1] := h1;
    end;
    fdata[aktnum].yver := aktyver;
  end;
  procedure resetch;
   var z1,z2 : integer;
       h1 : byte;
   begin
    for z1 := 0 to 7 do
    begin
     h1 := 0;
     for z2 := 0 to 7 do
      aktchar[z2+1,z1+1] := ((fdata[aktnum].map[z1] shr z2) and 1) = 1;
    end;
    aktyver := fdata[aktnum].yver;
  end;
  procedure savef;
   var f : file of _chmap;
       z1 : byte;
   begin
    setch;
    assign(f,fname);
    rewrite(f);
    for z1 := 0 to 255 do
     write(f,fdata[z1]);
    close(f);
  end;
  procedure loadf;
   var f : file of _chmap;
       z1 : byte;
   begin
    assign(f,fname);
    reset(f);
    for z1 := 0 to 255 do
     read(f,fdata[z1]);
    close(f);
    aktnum := 0;
    resetch;
    drawscreen;
  end;
  begin
   maus_status(mx,my,mbott);
   if inbott(5,20,12,20) then ende := true;
   if inbott(1,1,33,17) then
    if my mod 2 = 0 then
     if (mx-1) mod 4 > 0 then
      aktchar[(mx+2) div 4,my div 2] := not aktchar[(mx+2) div 4,my div 2];
   if inbott(23,22,25,24) then
   begin
    maus_aus;
    gotoxy(11,23);
    write('         ');
    gotoxy(11,23);
    readln(h3);
    val(h3,h1,h2);
    if (h2 > 0) or (h1 > 255) then drawscreen
     else begin
      aktnum := h1;
      resetch;
     end;
    maus_an;
   end;
   if inbott(5,24,9,24) and (aktnum > 0) then
   begin
    setch;
    dec(aktnum);
    resetch;
   end;
   if inbott(13,24,17,24) and (aktnum < 255) then
   begin
    setch;
    inc(aktnum);
    resetch;
   end;
   if inbott(40,2,48,2) then setch;
   if inbott(40,4,48,4) then resetch;
   if inbott(27,20,34,20) then savef;
   if inbott(16,20,23,20) then loadf;
   if mbott > 0 then
   begin
    repeat
     maus_status(mx,my,mbott);
    until mbott = 0;
    drawinfo;
   end;
 end;

 PROCEDURE InitData;
  var z1,z2 : integer;
  begin
   for z1 := 1 to 8 do
    for z2 := 1 to 8 do
     aktchar[z1,z2] := false;
   for z1 := 0 to 255 do
   with fdata[z1] do
   begin
    for z2 := 0 to 7 do
     map[z2] := 0;
    yver := 0;
   end;
 end;


 BEGIN
  initdata;
  drawscreen;
  maus_an;
  repeat
   menue;
  until ende;
  maus_aus;
END.