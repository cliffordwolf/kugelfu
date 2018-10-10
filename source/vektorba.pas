UNIT Vektorball;

 INTERFACE

  USES Mode_X,KF_Tools;

  TYPE __ball = ^_ball;

       _Ball = record
        vorher,nachher : __ball;
        x,y,z,rad : integer;
        col : byte;
       end;

  TYPE Vekball = object
        xmin,ymin,
        xmax,ymax,
        xmitt,ymitt,
        betrwert : word;
        schatten : boolean;
        schattentiefe : integer;
        aus_hinten,aus_vorne : word;
        list_pos,list_end : __ball;
        CONSTRUCTOR Init(x1,y1,x2,y2,xpos,ypos,betr : word);
        PROCEDURE Draw;
        PROCEDURE Del;
        PROCEDURE Add(_x,_y,_z,_rad,_col : integer);
        PROCEDURE Drawball(x,y,z,rad,col : integer);
        FUNCTION InScr(x1,y1,z1,x2,y2,z2 : integer) : boolean;
       end;

  PROCEDURE SaveMask(name : string);

  PROCEDURE Loadmask(name : string);

  PROCEDURE SetBallCol(nr,r,g,b,hell : byte);


 IMPLEMENTATION

 VAR maske : array [-42..42,-42..42] of byte;
     pal : array [0..31] of byte;
     helpmask : array [-80..80] of integer;


 FUNCTION Vekball.InScr(x1,y1,z1,x2,y2,z2 : integer) : boolean;
  var hx,hy,hz : integer;
      verkl : real;
  begin
   inscr := false;
   if z1 > z2 then hz := z1 else hz := z2;
   if hz < 0 then exit;
   verkl := betrwert/(betrwert+hz);
   x1 := round(x1*verkl);
   y1 := round(y1*verkl);
   x1 := x1+xmitt;
   y1 := y1+ymitt;
   x2 := round(x2*verkl);
   y2 := round(y2*verkl);
   x2 := x2+xmitt;
   y2 := y2+ymitt;
   if x1 > x2 then hx := x1 else hx := x2;
   if y1 > y2 then hy := y1 else hy := y2;
   if (hx < 0) or (hy < 0) then exit;
   if x1 < x2 then hx := x1 else hx := x2;
   if y1 < y2 then hy := y1 else hy := y2;
   if (hx > 320) or (hy > 200) then exit;
   inscr := true;
 end;

 PROCEDURE Vekball.Drawball(x,y,z,rad,col : integer);
  var zx,zy,hx,hy : integer;
      paddr : integer;
      verkl : real;
      hcol,c : byte;
  begin
   if z < 0 then exit;
   verkl := betrwert/(betrwert+z);
   rad := round(rad*verkl);
   if rad < 1 then rad := 1;
   if rad > 80 then rad := 80;
   x := round(x*verkl);
   y := round(y*verkl);
   x := x+xmitt;
   y := y+ymitt;
   if abs(x)-rad > 340 then exit;
   if abs(y)-rad > 220 then exit;
   for zx := -rad to rad do
    helpmask[zx] := zx*40 div rad;
   for zx := -rad to rad do
   begin
    port[$3c4] := 2;
    port[$3c5] := 1 shl ((zx+x) mod 4);
    paddr := (zx+x) shr 2 + (y-rad-1)*80 + vpage;
    hx := abs(zx);
    for zy := -rad to rad do
    begin
     hy := abs(zy);
     c := maske[helpmask[zx],helpmask[hy]];
     hcol := pal[col]+c-1;
     inc(paddr,80);

     if (hcol > 0) and (zx+x >= xmin) and (zx+x <= xmax) and
        (zy+y >= ymin) and (zy+y <= ymax) then
     asm
      mov ax,0a000h
      mov es,ax

      {mov ax,zx
      imul zx
      mov cx,ax
      mov ax,zy
      imul zy
      add cx,ax
      mov ax,rad
      imul rad
      cmp cx,ax
      ja @ende}

      mov al,c
      or al,al
      jz @ende

      mov ax,hx
      add ax,hy
      cmp ax,rad
      jne @L4

      mov ax,zy
      or ax,ax
      jns @L1
      neg ax
      @L1:
      cmp ax,rad
      jne @L2
      mov ax,zx
      or ax,ax
      jz @ende
      jmp @L4
      @L2:

      mov ax,zx
      or ax,ax
      jns @L3
      neg ax
      @L3:
      cmp ax,rad
      jne @L4
      mov ax,zy
      or ax,ax
      jz @ende
      @L4:

      mov di,paddr;
      mov al,hcol
      mov [es:di],al;
      @ende:
     end;
       {if ((zx*zx + zy*zy) <= rad*rad) and
        not((abs(zy) = rad) and (zx = 0)) and
        not((abs(zx) = rad) and (zy = 0)) then
        mem[$0a000 : paddr] := hcol;}
    end;
   end;
 end;


 PROCEDURE Vekball.Draw;
  var hp : __ball;
  begin
   hp := list_end;
   if hp <> nil then
   repeat
    with hp^ do
    drawball(x,y,z,rad,col);
    hp := hp^.vorher;
   until hp = nil;
 end;

 PROCEDURE Vekball.del;
  var hp,hp2 : __ball;
  begin
   if list_end = nil then exit;
   hp := list_end;
   repeat
    hp2 := hp^.vorher;
    dispose(hp);
    hp := hp2;
   until hp = nil;
   list_end := nil;
   list_pos := nil;
 end;

 PROCEDURE Vekball.add(_x,_y,_z,_rad,_col : integer);
  var hz1,hz2 : integer;
      hp,hp1,hp2 : __ball;
  begin
   new(hp);
   with hp^ do
   begin
    x := _x;
    y := _y;
    z := _z;
    rad := _rad;
    col := _col;
    vorher := nil;
    nachher := nil;
   end;
   if list_end = nil then list_end := hp
   else begin
    hp2 := list_pos;
    hp1 := list_pos^.nachher;
    repeat
     if (hp1^.z < _z) and (hp1 <> nil) then
     begin
      hp2 := hp1;
      hp1 := hp1^.nachher;
     end;
     if (hp2^.z > _z) and (hp2 <> nil) then
     begin
      hp1 := hp2;
      hp2 := hp2^.vorher;
     end;
    until ((hp1^.z >= _z) and (hp2^.z <= _z)) or (hp1 = nil) or (hp2 = nil);
    if hp1 = nil then
    begin
     hp2^.nachher := hp;
     list_end := hp;
     hp^.nachher := nil;
     hp^.vorher := hp2;
     list_pos := hp;
     exit;
    end;
    if hp2 = nil then
    begin
     hp1^.vorher := hp;
     hp^.vorher := nil;
     hp^.nachher := hp1;
     list_pos := hp;
     exit;
    end;
    hp^.nachher := hp1;
    hp^.vorher := hp2;
    hp1^.vorher := hp;
    hp2^.nachher := hp;
   end;
   list_pos := hp;
 end;

 CONSTRUCTOR Vekball.Init(x1,y1,x2,y2,xpos,ypos,betr : word);
  begin
   xmin := x1;
   ymin := y1;
   xmax := x2;
   ymax := y2;
   xmitt := xpos;
   ymitt := ypos;
   betrwert := betr;
   list_pos := nil;
   list_end := nil;
 end;

 PROCEDURE SetBallCol(nr,r,g,b,hell : byte);
  var z1 : integer;
      _r,_g,_b : real;
      abcol : byte;
  begin
   abcol := nr*16+1;
   getpal;
   inc(hell,15);
   _r := r;
   _g := g;
   _b := b;
   for z1 := 0 to 15 do
   begin
    palette[(z1+abcol)*3+0] := round(_r);
    palette[(z1+abcol)*3+1] := round(_g);
    palette[(z1+abcol)*3+2] := round(_b);
    _r := r*(hell-z1)/hell;
    _g := g*(hell-z1)/hell;
    _b := b*(hell-z1)/hell;
   end;
   setpal;
   pal[nr] := abcol;
 end;

 PROCEDURE Savemask(name : string);
  var f : file of byte;
      x,y : integer;
      h : byte;
  begin
   assign(f,name);
   rewrite(f);
   h := 28;
   write(f,h);
   h := 80;
   write(f,h);
   write(f,h);
   for x := -40 to 40 do
    for y := -40 to 40 do
     write(f,maske[x,y]);
   close(f);
 end;

 PROCEDURE Loadmask(name : string);
  var f : file of byte;
      x,y : integer;
      h : byte;
  begin
   for x := -42 to 42 do
    for y := -42 to 42 do
     maske[x,y] := 0;
   assign(f,name);
   reset(f);
   read(f,h);
   read(f,h);
   read(f,h);
   for x := -40 to 40 do
    for y := -40 to 40 do
     begin
      read(f,h);
      if x*x+y*y < 40*40 then maske[x,y] := h;
     end;
   close(f);
 end;

 BEGIN
END.