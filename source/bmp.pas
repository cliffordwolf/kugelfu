UNIT BMP;

INTERFACE

 USES Mode_X;

 TYPE _PAL = array [0..256*3-1] of byte;
      _SCR = array [0..65000] of byte;

      _BMP = object
       xausd,yausd : word;
       pal : ^_pal;
       memres : word;
       scr : array [0..3] of ^_scr; {Zeiger auf "Latches"}
       CONSTRUCTOR Init;
       FUNCTION Lade(fname : string) : boolean;
       PROCEDURE Zeichne(x,y : integer);
       PROCEDURE SetPalette;
       PROCEDURE GetPalette;
       PROCEDURE Scan(x1,y1,x2,y2 : word);
       PROCEDURE Save(fname : string);
       DESTRUCTOR Done;
      end;

IMPLEMENTATION

 CONSTRUCTOR _BMP.Init;
  begin
   xausd := 0;
   yausd := 0;
   pal := nil;
   scr[0] := nil;
   scr[1] := nil;
   scr[2] := nil;
   memres := 0;
 end;

 FUNCTION _BMP.Lade(fname : string) : boolean;
  var f : file;
      bildanf : longint;
      zx,zy : integer;
      hxausd : word;
  begin
   assign(f,fname);
   {$I-}
    reset(f,1);
   {$I+}
   if ioresult <> 0 then
   begin
    lade := false;
    exit;
   end;
   seek(f,$0A);
   blockread(f,bildanf,4);
   seek(f,$12);
   blockread(f,xausd,2);
   seek(f,$16);
   blockread(f,yausd,2);
   seek(f,$36);
   if pal = nil then new(pal);
   for zx := 0 to 255 do
   begin
    blockread(f,pal^[zx*3+2],1);
    blockread(f,pal^[zx*3+1],1);
    blockread(f,pal^[zx*3],1);
    seek(f,filepos(f)+1);
   end;
   seek(f,bildanf);
   if xausd mod 4 > 0 then hxausd := xausd + 4-xausd mod 4 else hxausd := xausd;
   for zx := 0 to 3 do
    if scr[zx] <> nil then freemem(scr[zx],memres);
   memres := yausd*(hxausd div 4 + 1);
   for zx := 0 to 3 do getmem(scr[zx],memres);
   for zy := 0 to yausd-1 do
    for zx := 0 to hxausd-1 do
     blockread(f,scr[zx mod 4]^[zx div 4 + ((yausd-1)-zy) * hxausd div 4],1);
   close(f);
 end;

 PROCEDURE _BMP.Zeichne(x,y : integer);
  var zl,zx,zy : word;
      hxausd : word;
      tox : word;
  begin
   if xausd mod 4 > 0 then hxausd := xausd + 4-xausd mod 4 else hxausd := xausd;
   for zl := 0 to 3 do
   begin
    putpixel(x+zl,y,0);
    if hxausd-(3-zl) <= xausd then tox := hxausd else tox := xausd;
    for zy := 0 to yausd-1 do
    for zx := 0 to (tox div 4)-1 do
    mem[$A000 : (zy+y)*80 + ((x+zl) div 4)+zx + vpage] := scr[zl]^[zx + zy*hxausd div 4];
   end;
 end;

 PROCEDURE _BMP.SetPalette;
  var z1 : word;
  begin
   for z1 := 0 to 256*3-1 do palette[z1] := pal^[z1] shr 2;
   setpal;
 end;

 PROCEDURE _BMP.GetPalette;
  var z1 : word;
  begin
   getpal;
   if pal = nil then new(pal);
   for z1 := 0 to 256*3-1 do pal^[z1] := palette[z1] shl 2;
 end;

 PROCEDURE _BMP.Scan(x1,y1,x2,y2 : word);
  var zl,zx,zy,hxausd,tox : word;
  begin
   for zx := 0 to 3 do
    if scr[zx] <> nil then freemem(scr[zx],memres);
   xausd := x2-x1+1;
   yausd := y2-y1+1;
   if xausd mod 4 > 0 then hxausd := xausd + 4-xausd mod 4 else hxausd := xausd;
   memres := yausd*(hxausd div 4 + 1);
   for zx := 0 to 3 do getmem(scr[zx],memres);
   for zl := 0 to 3 do
   begin
    getpixel(x1+zl,y1);
    if hxausd-(3-zl) <= xausd then tox := hxausd else tox := xausd;
    for zy := 0 to yausd-1 do
    for zx := 0 to (tox div 4)-1 do
    scr[zl]^[zx + zy*hxausd div 4] := mem[$A000 : (zy+y1)*80 + ((zl+x1) div 4)+zx + vpage];
   end;
 end;

 PROCEDURE _BMP.Save(fname : string);
  type _puf = array [0..65534] of byte;
  var f : file;
      h1 : char;
      z1,zx,zy : word;
      bildbegin,datgr,h3 : longint;
      hxausd,h2 : word;
  begin
   assign(f,fname);
   rewrite(f,1);
   h1 := 'B';
   blockwrite(f,h1,1);
   h1 := 'M';
   blockwrite(f,h1,1);
   h1 := chr(0);
   for z1 := 2 to 53 do blockwrite(f,h1,1);
   for z1 := 0 to 255 do
   begin
    blockwrite(f,pal^[z1*3+2],1);
    blockwrite(f,pal^[z1*3+1],1);
    blockwrite(f,pal^[z1*3],1);
    blockwrite(f,h1,1);
   end;
   bildbegin := filepos(f);
   if xausd mod 4 > 0 then hxausd := xausd + 4-xausd mod 4 else hxausd := xausd;
   for zy := 0 to yausd-1 do
    for zx := 0 to hxausd-1 do
     blockwrite(f,scr[zx mod 4]^[zx div 4 + ((yausd-1)-zy) * hxausd div 4],1);
   datgr := filepos(f);
   seek(f,2);
   blockwrite(f,datgr,4);
   seek(f,$A);
   blockwrite(f,bildbegin,4);
   seek(f,$0E);
   h3 := 40;
   blockwrite(f,h3,4);
   blockwrite(f,xausd,2);
   seek(f,$16);
   blockwrite(f,yausd,2);
   seek(f,$1A);
   h2 := 1;
   blockwrite(f,h2,2);
   h2 := 8;
   blockwrite(f,h2,2);
   seek(f,$22);
   h3 := hxausd*yausd;
   blockwrite(f,h3,4);
   close(f);
 end;

 DESTRUCTOR _BMP.Done;
  var z : byte;
  begin
   for z := 0 to 3 do
    if scr[z] <> nil then freemem(scr[z],memres);
   if pal <> nil then dispose(pal);
   init;
 end;


 BEGIN
END.