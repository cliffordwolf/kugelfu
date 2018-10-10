UNIT _Fight;

INTERFACE

 USES Mode_X,Vektorball,KF_Tools,KF_Objects,Crt,Bmp,_Menue;

 CONST Extras : boolean = false;
       Waithun : byte = 10;
       speedsum : longint = 0;
       speedanz : longint = 0;
       vollver = false;


 PROCEDURE Fight(p1,p2 : byte);


IMPLEMENTATION

 CONST Kasten : boolean = false;

 VAR CS,cs2 : Vekball;
     clock,cl2 : _clock;
     Sterne : array [0..255] of word;
     sternpos : integer;
     z1,h1 : integer;
     ch,ch2 : char;
     t1,t2 : _fighter;
     _t1,_t2 : __fighter;
     hp : pointer;
     schrittzaehler : longint;
     hrnd : integer;
     t3 : _bmp;
     endebegin : longint;
     sharehinw : boolean;


 PROCEDURE Line(x1,y1,z1,x2,y2,z2 : integer; farbe : byte);
  var x_add,y_add,hx,hy,v : real;
      schritte,z : integer;
  begin
   v := cs.betrwert/(cs.betrwert+z1);
   x1 := round(x1*v)+cs.xmitt;
   y1 := round(y1*v)+cs.ymitt;
   v := cs.betrwert/(cs.betrwert+z2);
   x2 := round(x2*v)+cs.xmitt;
   y2 := round(y2*v)+cs.ymitt;
   if (x1 <= 319) and (x1 >= 0) and (y1 <= 199) and (y1 >= 0) then putpixel(x1,y1,farbe);
   if (x1 = x2) and (y1 = y2) then exit;
   schritte := abs(x1-x2);
   if schritte < abs(y1-y2) then schritte := abs(y1-y2);
   x_add := (x1-x2)/schritte;
   y_add := (y1-y2)/schritte;
   hx := x2;
   hy := y2;
   for z := 0 to schritte do
   begin
    if (hx <= 319) and (hx >= 0) and (hy <= 199) and (hy >= 0) then putpixel(round(hx),round(hy),farbe);
    hx := hx+x_add;
    hy := hy+y_add;
   end;
 end;

 PROCEDURE Showit(wait : integer);
  type __hcs = array [1..26] of _ball;
       _hcs = ^__hcs;
  var z1 : integer;
      sharehin : boolean;
  procedure zeichneboden(z1,z2,y,streifenanf,breite : integer; col1,col2 : byte);
   var _z1,_z2 : integer;
       hy1,hy2 : word;
       v1,v2 : real;
   begin
    hy1 := round(cs.ymitt+cs.betrwert/(cs.betrwert+z2)*y)*80;
    hy2 := round(cs.ymitt+cs.betrwert/(cs.betrwert+z1)*y)*80;
    for _z1 := 0 to 319 do
    begin
     putpixel(_z1,hy2 div 80+1,col2);
      asm
       mov cx,hy1       {cx := hy1}
       mov dx,hy2       {dx := hy2}
       mov ax,$a000     {es := 0A000h}
       mov es,ax
       mov si,_z1       {si := _z1 shr 2 + vpage}
       shr si,2
       add si,vpage
       @L1:             {Schleifenanfang}
       mov di,si        {di := si+cx}
       add di,cx
       mov al,col1      {es:di := col1}
       mov es:[di],al
       add cx,80        {cx := cx+80}
       cmp cx,dx        {Wenn cx kleiner-gleich dx wiederhole}
       jbe @l1
      end;
    end;
    _z1 := -550+streifenanf;
    repeat
     line(_z1,y,z1,_z1,y,z2,col2);
     _z1 := _z1+breite;
    until _z1 > 550;
  end;
  procedure Zeichneschatten(_x,_y,_z : integer; col : byte; p : _hcs);
   var z1 : integer;
       y1,y2,x1,x2 : integer;
       v : real;
   procedure drawelipse;
    var zx,zy,y,x : integer;
    begin
     y := (y2-y1) div 2 + y1;
     x := (x2-x1) div 2 + x1;
     if (y2-y1) <> 0 then v := (x2-x1)/(y2-y1) else v := 1;
     for zx := x1 to x2 do
     if (zx >= 0) and (zx <= 319) then
     begin
      putpixel(zx,y,col);
      for zy := y2 to y1 do
       {if sqr(zx-x) + sqr((zy-y)*v) <= sqr((x2-x1) div 2) then}
        mem[$A000 : zx shr 2 + zy*80 + vpage] := col
     end;
   end;
   begin
    for z1 := 2 to 26 do
    with p^[z1] do
    begin
     v := cs.betrwert/(cs.betrwert+z+_z);
     x1 := round((x-rad+_x)*v)+cs.xmitt;
     x2 := round((x+rad+_x)*v)+cs.xmitt;
     v := cs.betrwert/(cs.betrwert+z-rad+_z);
     y1 := cs.ymitt+round((_y)*v);
     v := cs.betrwert/(cs.betrwert+z+rad+_z);
     y2 := cs.ymitt+round((_y)*v);
     drawelipse;
    end;
  end;
  procedure zeichneinfos;
   var z1,z2 : integer;
   begin
    if t1.energie > 0 then
    for z1 := 20 to 20+t1.energie do
    begin
     putpixel(z1,185,1*16+5);
     for z2 := 186 to 195 do mem[$A000:vpage+z2*80+z1 shr 2] := 1*16+5;
    end;
    if t2.energie > 0 then
    for z1 := 299 downto 299-t2.energie do
    begin
     putpixel(z1,185,4*16+5);
     for z2 := 186 to 195 do mem[$A000:vpage+z2*80+z1 shr 2] := 4*16+5;
    end;
  end;
  procedure zeichnetext(text : string);
   var h1 : vekball;
       h2 : _vbstring;
   begin
    inc(endebegin);
    h1.init(0,0,319,199,160,100,256);
    h2.init;
    if t1.aktion = 17 then h2.color := 4 else h2.color := 1;
    h2.text := text;
    h2.a1 := (endebegin mod 36) * 10;
    h2.a2 := h2.a1;
    h2.put2cs(1200-endebegin*20,-150,500,10,h1);
    h1.draw;
    h2.done;
    h1.del;
  end;
  begin
   sharehin := false;
   if sharehinw and (t1.energie+t2.energie < 120) then
   begin
    sharehinw := false;
    sharehin := true;
    share_indic;
   end;
   switch;
   waitretrace;
   delvpage;
   while sternpos < 0 do sternpos := sternpos+720;
   sternpos := sternpos mod 640;
   putpixel((sternpos shr 1) mod 4,0,0);
   for z1 := 0 to 200 do
    mem[$a000:sterne[z1]+vpage+sternpos shr 3] := 5;
   putpixel((sternpos mod 320) mod 4,0,0);
   for z1 := 201 to 255 do
    mem[$a000:sterne[z1]+vpage+(sternpos shr 2) mod 80] := 1;
   zeichneboden(400,800,200,(sternpos*7) mod 160,160,10,13);
   zeichneinfos;
   zeichneschatten(round(t1.gelenke[12].x-t1.hcs[t1.fixballnr].x)+t1.xpos
                   ,200,round(t1.gelenke[12].z-t1.hcs[t1.fixballnr].z)+t1.zpos
                   ,13,addr(t1.hcs));
   zeichneschatten(round(t2.gelenke[12].x-t2.hcs[t2.fixballnr].x)+t2.xpos
                   ,200,round(t2.gelenke[12].z-t2.hcs[t2.fixballnr].z)+t2.zpos
                   ,13,addr(t2.hcs));
   if kasten then
   with t1 do
   begin
    line(inx1,iny1,inz2,inx2,iny1,inz2,35);
    line(inx2,iny1,inz2,inx2,iny2,inz2,35);
    line(inx2,iny2,inz2,inx1,iny2,inz2,35);
    line(inx1,iny2,inz2,inx1,iny1,inz2,35);
    line(inx1,iny1,inz2,inx1,iny1,inz1,35);
    line(inx2,iny1,inz2,inx2,iny1,inz1,35);
    line(inx2,iny2,inz2,inx2,iny2,inz1,35);
    line(inx1,iny2,inz2,inx1,iny2,inz1,35);
   end;
   if kasten then
   with t2 do
   begin
    line(inx1,iny1,inz2,inx2,iny1,inz2,35);
    line(inx2,iny1,inz2,inx2,iny2,inz2,35);
    line(inx2,iny2,inz2,inx1,iny2,inz2,35);
    line(inx1,iny2,inz2,inx1,iny1,inz2,35);
    line(inx1,iny1,inz2,inx1,iny1,inz1,35);
    line(inx2,iny1,inz2,inx2,iny1,inz1,35);
    line(inx2,iny2,inz2,inx2,iny2,inz1,35);
    line(inx1,iny2,inz2,inx1,iny2,inz1,35);
   end;
   cs2.draw;
   cs2.del;
   cs.draw;
   cs.del;
   if (t1.aktion = 17) or (t2.aktion = 17) then
    if t1.aktion = 17 then zeichnetext('PLAYER 2 WON!')
    else zeichnetext('PLAYER 1 WON!');
   if kasten then
   with t1 do
   begin
    line(inx1,iny1,inz1,inx2,iny1,inz1,35);
    line(inx2,iny1,inz1,inx2,iny2,inz1,35);
    line(inx2,iny2,inz1,inx1,iny2,inz1,35);
    line(inx1,iny2,inz1,inx1,iny1,inz1,35);
   end;
   if kasten then
   with t2 do
   begin
    line(inx1,iny1,inz1,inx2,iny1,inz1,35);
    line(inx2,iny1,inz1,inx2,iny2,inz1,35);
    line(inx2,iny2,inz1,inx1,iny2,inz1,35);
    line(inx1,iny2,inz1,inx1,iny1,inz1,35);
   end;
   if (not sharehin) and (endebegin = 0) then
   begin
    speedsum := speedsum+clock.time;
    inc(speedanz);
   end;
   repeat until clock.time > wait;
   clock.stop;
 end;

 FUNCTION KI_Hardest(ich : __Fighter) : char;
  var xich,xfeind : integer;
      ki : char;
  begin
   randomize;
   hrnd := hrnd+schrittzaehler mod 11+random(random(30));
   hrnd := abs(hrnd);
   if abs(ich^.inx2-ich^.feind^.inx1) < abs(ich^.inx1-ich^.feind^.inx2) then
   begin
    xich := ich^.inx2;
    xfeind := ich^.feind^.inx1;
   end else begin
    xich := ich^.inx1;
    xfeind := ich^.feind^.inx2;
   end;
   if (ich^.feind^.aktion in [0,11..17])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 4 of
     0 : ki := '-';
     1 : ki := '2';
     2 : ki := '*';
     3 : ki := '3';
    end else
    case hrnd mod 4 of
     0 : if hrnd mod 16 = 1 then ki := ',';
     1 : if (hrnd mod 16 = 1) and (abs(xich-xfeind) > 200) then ki := '/';
     2 : if (xfeind < xich) then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if (ich^.feind^.aktion in [1])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 250 then
    case hrnd mod 2 of
     0 : if xfeind < xich then ki := '7' else ki := '9';
     1 : if xfeind < xich then ki := '4' else ki := '6';
    end else
    case hrnd mod 6 of
     0 : if hrnd mod 18 = 1 then ki := ',';
     1 : if hrnd mod 18 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if (ich^.feind^.aktion in [2])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 250 then
    case hrnd mod 2 of
     0 : if xfeind < xich then ki := '9' else ki := '7';
     1 : if xfeind < xich then ki := '4' else ki := '6';
    end else
    case hrnd mod 4 of
     0 : if hrnd mod 16 = 1 then ki := ',';
     1 : if hrnd mod 16 = 1 then ki := '/';
     2 : ki := '6';
     3 : ki := '4';
    end;
   end;
   if ich^.feind^.aktion = 3 then
    if ich^.feind^.pc.ip < 42 then ki := '*' else ki := '/';
   if ich^.feind^.aktion in [4,5] then
    if abs(xich-xfeind) < 270 then ki := '5'
     else if xfeind < xich then ki := '4' else ki := '6';
   if ich^.feind^.aktion in [8,9] then
    if abs(xich-xfeind) < 270 then ki := '5'
     else ki := '/';
   if ich^.feind^.aktion in [6] then
    if abs(xich-xfeind) < 270 then ki := '-' else ki := '/';
   if ich^.feind^.aktion in [7] then
    if abs(xich-xfeind) < 270 then ki := '3' else ki := '/';
   if ich^.feind^.aktion in [10] then ki := '0';
   if (ich^.aktion = 2) and ((ich^.feind^.aktion <> 10) or
      ((ich^.feind^.gelenke[13].speedx < 0) and (ich^.feind^.gelenke[13].x < ich^.inx1))
      or ((ich^.feind^.gelenke[13].speedx > 0) and (ich^.feind^.gelenke[13].x > ich^.inx2))) then
    if abs(xich-xfeind) < 300 then ki := '3' else ki := chr(13);
   if (ich^.aktion = 12) and
      ((ich^.inx2 > ich^.feind^.inx1) and (ich^.inx1 < ich^.feind^.inx2))
      and (ich^.feind^.iny1 > ich^.iny2) then ki := '+';
   if (ich^.feind^.aktion = 17) then ki := '*';
   if (ich^.aktion = 3) then ki := chr(13);
   if (ich^.aktion = 16) then ki := chr(13);
   ki_hardest := ki;
 end;

 FUNCTION KI_Hard(ich : __Fighter) : char;
  var xich,xfeind : integer;
      ki : char;
  begin
   randomize;
   hrnd := hrnd+schrittzaehler mod 11+random(random(30));
   hrnd := abs(hrnd);
   if abs(ich^.inx2-ich^.feind^.inx1) < abs(ich^.inx1-ich^.feind^.inx2) then
   begin
    xich := ich^.inx2;
    xfeind := ich^.feind^.inx1;
   end else begin
    xich := ich^.inx1;
    xfeind := ich^.feind^.inx2;
   end;
   if (ich^.feind^.aktion in [0,11..17])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 6 of
     0 : ki := '-';
     1 : ki := '2';
     2 : ki := '+';
     3 : ki := '1';
     4 : ki := '*';
     5 : ki := '3';
    end else
    case hrnd mod 6 of
     0 : if hrnd mod 18 = 1 then ki := ',';
     1 : if hrnd mod 18 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
     4 : if xfeind < xich then ki := '4' else ki := '6';
     5 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if (ich^.feind^.aktion in [1])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 2 of
     0 : ki := '+';
     1 : ki := '1';
    end else
    case hrnd mod 6 of
     0 : if hrnd mod 18 = 1 then ki := ',';
     1 : if hrnd mod 18 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
     4 : if xfeind < xich then ki := '4' else ki := '6';
     5 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if (ich^.feind^.aktion in [2])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 5 of
     1 : ki := '4';
     2 : ki := '+';
     3 : ki := '1';
    end else
    case hrnd mod 4 of
     0 : if hrnd mod 16 = 1 then ki := ',';
     1 : if hrnd mod 16 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if ich^.feind^.aktion = 3 then
    if ich^.feind^.pc.ip < 42 then ki := '*' else ki := '/';
   if ich^.feind^.aktion in [4,5] then
    if abs(xich-xfeind) < 270 then ki := '5'
     else if xfeind < xich then ki := '4' else ki := '6';
   if ich^.feind^.aktion in [8,9] then
    if abs(xich-xfeind) < 270 then ki := '5'
     else ki := '/';
   if ich^.feind^.aktion in [6] then
    if abs(xich-xfeind) < 270 then ki := '-' else ki := '/';
   if ich^.feind^.aktion in [7] then
    if abs(xich-xfeind) < 270 then ki := '3' else ki := '/';
   if ich^.feind^.aktion in [10] then ki := '0';
   if (ich^.aktion = 2) and ((ich^.feind^.aktion <> 10) or
      ((ich^.feind^.gelenke[13].speedx < 0) and (ich^.feind^.gelenke[13].x < ich^.inx1))
      or ((ich^.feind^.gelenke[13].speedx > 0) and (ich^.feind^.gelenke[13].x > ich^.inx2))) then
    if abs(xich-xfeind) < 300 then ki := '3' else ki := chr(13);
   if (ich^.aktion = 12) and
      ((ich^.inx2 > ich^.feind^.inx1) and (ich^.inx1 < ich^.feind^.inx2))
      and (ich^.feind^.iny1 > ich^.iny2) then ki := '+';
   if (ich^.feind^.aktion = 17) then ki := '*';
   if (ich^.aktion = 3) then ki := chr(13);
   if (ich^.aktion = 16) then ki := chr(13);
   ki_hard := ki;
 end;

 FUNCTION KI_Middle(ich : __Fighter) : char;
  var xich,xfeind : integer;
      ki : char;
  begin
   randomize;
   hrnd := hrnd+schrittzaehler mod 11+random(random(30));
   hrnd := abs(hrnd);
   if abs(ich^.inx2-ich^.feind^.inx1) < abs(ich^.inx1-ich^.feind^.inx2) then
   begin
    xich := ich^.inx2;
    xfeind := ich^.feind^.inx1;
   end else begin
    xich := ich^.inx1;
    xfeind := ich^.feind^.inx2;
   end;
   if (ich^.feind^.aktion in [0,11..17])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 6 of
     0 : ki := '-';
     1 : ki := '2';
     2 : ki := '+';
     3 : ki := '1';
     4 : ki := '*';
     5 : ki := '3';
    end else
    case hrnd mod 6 of
     0 : if hrnd mod 18 = 1 then ki := ',';
     1 : if hrnd mod 18 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
     4 : if xfeind < xich then ki := '4' else ki := '6';
     5 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if (ich^.feind^.aktion in [1])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 2 of
     0 : ki := '+';
     1 : ki := '1';
    end else
    case hrnd mod 6 of
     0 : if hrnd mod 18 = 1 then ki := ',';
     1 : if hrnd mod 18 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
     4 : if xfeind < xich then ki := '4' else ki := '6';
     5 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if (ich^.feind^.aktion in [2])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 6 of
     1 : ki := '2';
     3 : ki := '1';
    end else
    case hrnd mod 4 of
     0 : if hrnd mod 16 = 1 then ki := ',';
     1 : if hrnd mod 16 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if ich^.feind^.aktion = 3 then
    if ich^.feind^.pc.ip < 42 then ki := '5' else ki := '/';
   if ich^.feind^.aktion in [4,5] then
    if abs(xich-xfeind) < 270 then ki := '5'
     else if xfeind < xich then ki := '4' else ki := '6';
   if ich^.feind^.aktion in [8,9] then
    if abs(xich-xfeind) < 270 then ki := '5'
     else ki := '/';
   if ich^.feind^.aktion in [6] then
    if abs(xich-xfeind) < 270 then ki := '-' else ki := '/';
   if ich^.feind^.aktion in [7] then
    if abs(xich-xfeind) < 270 then ki := '3' else ki := '/';
   if ich^.feind^.aktion in [10] then ki := '0';
   if (ich^.aktion = 2) and (ich^.feind^.aktion <> 10) then
    if abs(xich-xfeind) < 300 then ki := '3' else ki := chr(13);
   if (ich^.aktion = 12) and
      ((ich^.inx2 > ich^.feind^.inx1) and (ich^.inx1 < ich^.feind^.inx2))
      and (ich^.feind^.iny1 > ich^.iny2)
      and (ich^.feind^.inx2 mod 3 = 1) then ki := '+';
   if (ich^.feind^.aktion = 17) then ki := '*';
   if (ich^.aktion = 3) then ki := chr(13);
   if (ich^.aktion = 16) then ki := chr(13);
   if (hrnd*xfeind-xich mod 35) = 0 then ki := '+';
   if (hrnd*xfeind-xich mod 35) = 1 then ki := '8';
   if (hrnd*xfeind-xich mod 35) in [2..5] then ki := chr(13);
   if (hrnd*xfeind-xich mod 35) in [6..10] then ki := '~';
   ki_middle := ki;
 end;

 FUNCTION KI_Simple(ich : __Fighter) : char;
  var xich,xfeind : integer;
      ki : char;
  begin
   randomize;
   hrnd := hrnd+schrittzaehler mod 11+random(random(30));
   hrnd := abs(hrnd);
   if abs(ich^.inx2-ich^.feind^.inx1) < abs(ich^.inx1-ich^.feind^.inx2) then
   begin
    xich := ich^.inx2;
    xfeind := ich^.feind^.inx1;
   end else begin
    xich := ich^.inx1;
    xfeind := ich^.feind^.inx2;
   end;
   if (ich^.feind^.aktion in [0,11..17])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 6 of
     0 : ki := '-';
     1 : ki := '2';
     2 : ki := '+';
     3 : ki := '1';
     4 : ki := '*';
     5 : ki := '3';
    end else
    case hrnd mod 6 of
     0 : if hrnd mod 18 = 1 then ki := ',';
     1 : if hrnd mod 18 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
     4 : if xfeind < xich then ki := '4' else ki := '6';
     5 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if (ich^.feind^.aktion in [1])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 2 of
     0 : ki := '+';
     1 : ki := '1';
    end else
    case hrnd mod 6 of
     0 : if hrnd mod 18 = 1 then ki := ',';
     1 : if hrnd mod 18 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
     4 : if xfeind < xich then ki := '4' else ki := '6';
     5 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if (ich^.feind^.aktion in [2])
      and not(ich^.aktion in [11..14]) then
   begin
    if abs(xich-xfeind) < 30 then
    case hrnd mod 6 of
     1 : ki := '2';
     3 : ki := '1';
    end else
    case hrnd mod 4 of
     0 : if hrnd mod 16 = 1 then ki := ',';
     1 : if hrnd mod 16 = 1 then ki := '/';
     2 : if xfeind < xich then ki := '7' else ki := '9';
     3 : if xfeind < xich then ki := '4' else ki := '6';
    end;
   end;
   if ich^.feind^.aktion = 3 then
    if ich^.feind^.pc.ip < 42 then ki := '5' else ki := '/';
   if ich^.feind^.aktion in [4,5] then
    if abs(xich-xfeind) < 270 then ki := '5'
     else if xfeind < xich then ki := '4' else ki := '6';
   if ich^.feind^.aktion in [8,9] then
    if abs(xich-xfeind) < 270 then ki := '5'
     else ki := '/';
   if ich^.feind^.aktion in [6] then
    if (abs(xich-xfeind) < 270) and (hrnd mod 3 > 1) then ki := '-';
   if ich^.feind^.aktion in [7] then
    if (abs(xich-xfeind) < 270) and (hrnd mod 3 > 1) then ki := '3';
   if ich^.feind^.aktion in [10] then ki := '0';
   if (ich^.aktion = 2) and (ich^.feind^.aktion <> 10) then ki := chr(13);
   if (ich^.aktion = 12) and
      ((ich^.inx2 > ich^.feind^.inx1) and (ich^.inx1 < ich^.feind^.inx2))
      and (ich^.feind^.iny1 > ich^.iny2)
      and (ich^.feind^.inx2 mod 7 = 1) then ki := '+';
   if (ich^.feind^.aktion = 17) then ki := '*';
   if (ich^.aktion = 3) then ki := chr(13);
   if (ich^.aktion = 16) then ki := chr(13);
   if (hrnd*xfeind-xich mod 35) in [0..3] then ki := '+';
   if (hrnd*xfeind-xich mod 35) in [3..10]  then ki := '8';
   if (hrnd*xfeind-xich mod 35) in [10..18] then ki := chr(13);
   if (hrnd*xfeind-xich mod 35) in [19..27] then ki := '~';
   ki_simple := ki;
 end;

 FUNCTION KI_Hyper(ich : __Fighter) : char;
  var auswahl : string;
      xich,xfeind : integer;
      feind : __fighter;
      ki : char;
  begin
   feind := ich^.feind;
   if abs(ich^.inx2-feind^.inx1) < abs(ich^.inx1-feind^.inx2) then
   begin
    xich := ich^.inx2;
    xfeind := feind^.inx1;
   end else begin
    xich := ich^.inx1;
    xfeind := feind^.inx2;
   end;

   auswahl := '~466'+chr(13);
   if (abs(xich-xfeind)>100) then auswahl := auswahl+'/';
   if (abs(xich-xfeind)>70) then auswahl := auswahl+'9';
   if (abs(xich-xfeind)<70) then auswahl := auswahl+'3-2*';
   ki := auswahl[random(length(auswahl))+1]; randomize;
   if (feind^.aktion in [6,7])
      and (abs(xich-xfeind)<30) then ki := '2';
   if (feind^.aktion = 12)
      and (abs(xich-xfeind)<30) then ki := '*';
   if (feind^.aktion in [4,5,8,9])
      and (abs(xich-xfeind)<30) then ki := '5';
   if ich^.aktion = 1 then ki := '3';
   if feind^.aktion = 10 then ki := '0';
   if ich^.aktion in [3,16] then ki :=  chr(13);
   if (ki = '9') and (xich < xfeind) then ki := ',';
   if (ki = '7') and (xich > xfeind) then ki := ',';
   if xfeind < xich then
   case ki of
    '4' : ki := '6';
    '6' : ki := '4';
    '7' : ki := '9';
    '9' : ki := '7';
   end;
   if (ich^.feind^.aktion = 17) then ki := '*';
   if ki = '~' then ki := '5';
   ki_hyper := ki;
   ki := ki_hardest(ich);
   if ki in ['3','/','0'] then ki_hyper := ki;
   if (ki = '+') and (random(3) = 0) then ki_hyper := ki;
 end;

 PROCEDURE Fight(p1,p2 : byte);
  begin
   endebegin := 0;
   for z1 := 0 to 255 do
    sterne[z1] := random(16000-80);
   clrscr;
   writeln;
   clrscr;
   init_modex;
   cs.init(0,0,319,199,160,100,256);
   cs2.init(0,0,319,199,160,100,256);
   setballcol(0,63,63,40,1);
   setballcol(1,63,31,0,1);
   setballcol(2,30,63,30,1);
   setballcol(3,30,20,40,1);
   setballcol(4,20,40,40,1);
   t1.init(-250,200,600,addr(t2));
   case p1 of
    7 : t1.treffermin := 0;
    6 : t1.treffermin := 1;
    5 : t1.treffermin := 2;
    else t1.treffermin := 3;
   end;
   t1.color[1] := 1;
   t1.color[2] := 1;
   t1.color[3] := 1;
   t1.setfixballnr(24);
   t1.fallen(1);
   t1.yendrot := 90;
   t2.init(250,200,600,addr(t1));
   case p2 of
    7 : t2.treffermin := 0;
    6 : t2.treffermin := 1;
    5 : t2.treffermin := 2;
    else t2.treffermin := 3;
   end;
   t2.color[1] := 4;
   t2.color[2] := 4;
   t2.color[3] := 4;
   t2.setfixballnr(24);
   t2.fallen(1);
   t2.yendrot := 270;
   cl2.stop;
   clock.stop;
   schrittzaehler := 0;
   sternpos := 0;
   sharehinw := demo;
   _t1 := addr(t1);
   _t2 := addr(t2);
   repeat
    inc(schrittzaehler);
    showit(waithun);
    hp := _t1;
    _t1 := _t2;
    _t2 := hp;
    _t1^.move;
    _t2^.move;
    _t1^.go;
    _t2^.go;
    _t1^.draw;
    _t2^.draw;
    _t1^.put2cs(cs);
    _t2^.put2cs(cs2);
    mem[$0000:$0417] := mem[$0000:$0417] or (1 shl 5);
    if keypressed then ch := upcase(readkey)
     else ch := '~';
    if extras then
    begin
     if ch = 'B' then
     begin
      t3.init;
      if vpage = 0 then vpage := 16000 else vpage := 0;
      t3.scan(0,0,319,199);
      t3.getpalette;
      t3.save('scrshot.bmp');
      if vpage = 0 then vpage := 16000 else vpage := 0;
      t3.done;
     end;
     if ch = 'K' then kasten := not kasten;
     ch2 := chr(0);
     if ord(ch) = 0 then ch2 := readkey;
     {F1 - F4 gedrckt}
     if ord(ch2) = 59 then t1.energie := 100;
     if ord(ch2) = 60 then t1.aktion := 15;
     if ord(ch2) = 61 then t1.aktion := 16;
     if ord(ch2) = 62 then t1.aktion := 17;
     if ord(ch2) in [60..62] then t1.getroffen := 2*(ord(ch2)-59);
     {F5 - F8 gedrckt}
     if ord(ch2) = 63 then t2.energie := 100;
     if ord(ch2) = 64 then t2.aktion := 15;
     if ord(ch2) = 65 then t2.aktion := 16;
     if ord(ch2) = 66 then t2.aktion := 17;
     if ord(ch2) in [64..66] then t2.getroffen := 2*(ord(ch2)-63);
    end;
    while keypressed do readkey;
    ch2 := '~';
    case ch of
     'Y' : ch2 := '1';
     'X' : ch2 := '2';
     'C' : ch2 := '3';
     'A' : ch2 := '4';
     'S' : ch2 := '5';
     'D' : ch2 := '6';
     'Q' : ch2 := '7';
     'W' : ch2 := '8';
     'E' : ch2 := '9';
     ' ' : ch2 := '0';
     'V' : ch2 := ',';
     'F' : ch2 := chr(13);
     'R' : ch2 := '+';
     'T' : ch2 := '-';
     'G' : ch2 := '*';
     'B' : ch2 := '/';
    end;
    if not (ord(ch) in [27,13,42..45,47..57]) then ch := '~';
    if (ord(ch) <> 27) and (endebegin > 20) then
    case (abs(endebegin+t1.inx1-t2.inx2) mod 7) of
     1 : ch := ',';
     2 : ch := '*';
     3 : ch := '3';
     4 : ch := '8';
     5 : ch := '7';
     6 : ch := '9';
     else ch := '1';
    end;
    if endebegin > 20 then t1.setaktion(ch)
    else case p1 of
     1 : t1.setaktion(ch2);
     2 : t1.setaktion(ch);
     3 : t1.setaktion(ki_simple(addr(t1)));
     4 : t1.setaktion(ki_middle(addr(t1)));
     5 : if vollver then t1.setaktion(ki_hard(addr(t1)));
     6 : if vollver then t1.setaktion(ki_hardest(addr(t1)));
     7 : if vollver then t1.setaktion(ki_hyper(addr(t1)));
    end;
    if endebegin > 20 then t2.setaktion(ch)
    else case p2 of
     1 : t2.setaktion(ch2);
     2 : t2.setaktion(ch);
     3 : t2.setaktion(ki_simple(addr(t2)));
     4 : t2.setaktion(ki_middle(addr(t2)));
     5 : if vollver then t2.setaktion(ki_hard(addr(t2)));
     6 : if vollver then t2.setaktion(ki_hardest(addr(t2)));
     7 : if vollver then t2.setaktion(ki_hyper(addr(t2)));
    end;
    if t1.xpos > 700 then t1.xpos := 700;
    if t1.xpos < -700 then t1.xpos := -700;
    if t2.xpos > 700 then t2.xpos := 700;
    if t2.xpos < -700 then t2.xpos := -700;
    if (t2.xpos+t1.xpos) div 2 > 50 then
    begin
     dec(t1.xpos,7);
     dec(t2.xpos,7);
     dec(sternpos);
    end;
    if (t2.xpos+t1.xpos) div 2 < -50 then
    begin
     inc(t1.xpos,7);
     inc(t2.xpos,7);
     inc(sternpos);
    end;
   until (endebegin > 140) or (ord(ch) = 27);
   fade_out;
   textmode(3);
 end;

 BEGIN
END.