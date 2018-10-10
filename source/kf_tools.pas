UNIT KF_Tools;

 INTERFACE

 USES Mode_X,Dos;

 TYPE _Clock = OBJECT
       stoptime : longint;
       CONSTRUCTOR Stop;
       FUNCTION Time : word; {in Hundertstel}
      end;

 PROCEDURE DelVPage;

 FUNCTION X_Rot(strecke,winkel : real) : integer;

 FUNCTION Y_Rot(strecke,winkel : real) : integer;

 PROCEDURE RotUmX(var x,y,z : integer; winkel : real);

 PROCEDURE RotUmY(var x,y,z : integer; winkel : real);

 PROCEDURE RotUmZ(var x,y,z : integer; winkel : real);

 FUNCTION GetWinkel(x,y : integer) : integer;

 FUNCTION GetRad(x,y : integer) : integer;

 PROCEDURE PrepLists;


 IMPLEMENTATION

 TYPE _winktab = array [0..360] of integer;
      _radtab = array [0..127,0..127] of integer;

 VAR costab : ^_winktab;
     sintab : ^_winktab;
     radtab : ^_radtab;
     z1,z2 : integer;

 CONSTRUCTOR _Clock.Stop;
  var st,min,sec,hun : word;
  begin
   gettime(st,min,sec,hun);
   stoptime := min*60*100+sec*100+hun;
 end;

 FUNCTION _Clock.Time : word;
  var st,min,sec,hun,ht : word;
      h1 : longint;
  begin
   gettime(st,min,sec,hun);
   h1 := min*60*100+sec*100+hun;
   if h1 < stoptime then
    ht := h1+59*60*100+59*100+99-stoptime
    else ht := h1-stoptime;
   time := ht;
 end;

 PROCEDURE DelVPage; assembler;
  asm
   mov ax,0f02h
   mov dx,3c4h
   out dx,ax
   mov di,0a000h
   mov es,di
   mov di,vpage
   xor ax,ax
   cld
   mov cx,16000
   rep stosb
 end;

 FUNCTION X_Rot(strecke,winkel : real) : integer;
  begin
   x_rot := round(strecke*costab^[round(winkel)]/32000);
 end;

 FUNCTION Y_Rot(strecke,winkel : real) : integer;
  begin
   y_rot := round(strecke*sintab^[round(winkel)]/32000);
 end;

 FUNCTION GetRad(x,y : integer) : integer;
  var h1 : integer;
      verkl : real;
  begin
   x := abs(x);
   y := abs(y);
   verkl := 1.000;
   h1 := x;
   if y > x then h1 := y;
   if h1 > 127 then
   begin
    verkl := h1/127;
    x := round(x/verkl);
    y := round(y/verkl);
   end;
   h1 := radtab^[x,y];
   if verkl <> 1 then
    h1 := round(h1*verkl);
   getrad := h1;
 end;

 FUNCTION GetWinkel(x,y : integer) : integer;
  var z1 : integer;
      hx,hy,ha,hw,tempw : integer;
      h1,h2 : real;
  begin
   if (y = 0) or (x = 0) then
   begin
    getwinkel := 0;
    if (y = 0) and (x < 0) then getwinkel := 180;
    if (y < 0) and (x = 0) then getwinkel := 270;
    if (y > 0) and (x = 0) then getwinkel := 90;
    exit;
   end;
   if (x < 0) and (y < 0) then
   begin
    hx := -y;
    hy :=  -x;
    ha := 90;
   end;
   if (x < 0) and (y > 0) then
   begin
    hx := -x;
    hy := y;
    ha := 180;
   end;
   if (x > 0) and (y > 0) then
   begin
    hx := y;
    hy := x;
    ha := 270;
   end;
   if (x > 0) and (y < 0) then
   begin
    hx := x;
    hy := -y;
    ha := 0;
   end;

   h1 := 10000000.0000000;
   h1 := h1*(hx/hy);
   for z1 := 0 to 8 do
   begin
    h2 := abs(hx/hy - costab^[z1*10+5]/sintab^[z1*10+5]);
    if h1 > h2 then
    begin
     h1 := h2;
     hw := z1*10+5;
    end;
   end;
   tempw := hw;
   for z1 := tempw-5 to tempw+5 do
   begin
    h2 := abs(hx/hy - costab^[z1]/sintab^[z1]);
    if h1 > h2 then
    begin
     h1 := h2;
     hw := z1;
    end;
   end;

   getwinkel := 360 - (hw+ha) mod 360;
 end;

 PROCEDURE RotUmX(var x,y,z : integer; winkel : real);
  var hz,hy,hw : integer;
  begin
   while winkel < 0 do winkel := winkel+360;
   winkel := round(winkel) mod 360;
   hw := 360-round(winkel);
   if hw = 0 then exit;
   hz := x_rot(z,hw) - y_rot(y,hw);
   hy := y_rot(z,hw) + x_rot(y,hw);

   z := hz;
   y := hy;
 end;

 PROCEDURE RotUmY(var x,y,z : integer; winkel : real);
  var hw,hx,hz : integer;
  begin
   while winkel < 0 do winkel := winkel+360;
   winkel := round(winkel) mod 360;
   hw := round(winkel);
   if hw = 0 then exit;
   hx := x_rot(x,hw) - y_rot(z,hw);
   hz := y_rot(x,hw) + x_rot(z,hw);
   x := hx;
   z := hz;
 end;

 PROCEDURE RotUmZ(var x,y,z : integer; winkel : real);
  var hw,hx,hy : integer;
  begin
   while winkel < 0 do winkel := winkel+360;
   winkel := round(winkel) mod 360;
   hw := round(winkel);
   if hw = 0 then exit;
   hx := x_rot(x,hw) - y_rot(y,hw);
   hy := y_rot(x,hw) + x_rot(y,hw);
   x := hx;
   y := hy;
 end;

 FUNCTION _Cos(winkel : real) : real;
  begin
   if winkel >= 360 then
   repeat
    winkel := winkel-360;
   until winkel < 360;
   _cos := cos(winkel*pi/180);
 end;

 FUNCTION _Sin(winkel : real) : real;
  begin
   if winkel >= 360 then
   repeat
    winkel := winkel-360;
   until winkel < 360;
   _sin := sin(winkel*pi/180);
 end;

 PROCEDURE PrepLists;
  begin
   new(costab);
   new(sintab);
   new(radtab);
   for z1 := 0 to 360 do
   begin
    costab^[z1] := round(_cos(z1)*32000+1);
    sintab^[z1] := round(_sin(z1)*32000+1);
   end;
   for z1 := 0 to 127 do
   for z2 := 0 to 127 do
    radtab^[z1,z2] := round(sqrt(z1*z1+z2*z2));
 end;


 BEGIN
END.