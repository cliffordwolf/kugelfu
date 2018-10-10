UNIT _IDENT;

INTERFACE

 TYPE _identblock = record
                     username : string;
                     usernumber : word;
                     progsize : longint;
                     chk1,chk2 : byte;
                    end;

 VAR identblock : _identblock;

 PROCEDURE Ident_Lade(fname : string);

 PROCEDURE Ident_Save(fname : string);

 PROCEDURE Ident_ReadDat(fname : string);

 FUNCTION Ident_Teste(fname : string) : boolean;


IMPLEMENTATION

 CONST chkxor = 123;

       falsch : boolean = false;

 TYPE _byte = ^byte;

 PROCEDURE Codiere(p : _byte);
  var h1,h2 : _byte;
      z1 : word;
  begin
   h1 := @identblock;
   h2 := p;
   for z1 := 1 to sizeof(_identblock) do
   begin
    h2^ := h1^ xor chkxor;
    h1 := ptr(seg(h1^),ofs(h1^)+1);
    h2 := ptr(seg(h2^),ofs(h2^)+1);
   end;
   h1 := @identblock;
   for z1 := 1 to sizeof(_identblock) do
   begin
    h2^ := h1^ xor $FF;
    h1 := ptr(seg(h1^),ofs(h1^)+1);
    h2 := ptr(seg(h2^),ofs(h2^)+1);
   end;
 end;

 PROCEDURE DeCodiere(p : _byte);
  var h1,h2 : _byte;
      z1 : word;
  begin
   h2 := @identblock;
   h1 := p;
   for z1 := 1 to sizeof(_identblock) do
   begin
    h2^ := h1^ xor chkxor;
    h1 := ptr(seg(h1^),ofs(h1^)+1);
    h2 := ptr(seg(h2^),ofs(h2^)+1);
   end;
   h2 := @identblock;
   for z1 := 1 to sizeof(_identblock) do
   begin
    if h2^ <> h1^ xor $FF then falsch := true;
    h1 := ptr(seg(h1^),ofs(h1^)+1);
    h2 := ptr(seg(h2^),ofs(h2^)+1);
   end;
 end;

 PROCEDURE Ident_Lade(fname : string);
  var f : file;
      p : _byte;
  begin
   assign(f,fname);
   reset(f,1);
   getmem(p,sizeof(_identblock)*2);
   blockread(f,p^,sizeof(_identblock)*2);
   decodiere(p);
   freemem(p,sizeof(_identblock)*2);
   close(f);
 end;

 PROCEDURE Ident_Save(fname : string);
  var f : file;
      p : _byte;
  begin
   assign(f,fname);
   rewrite(f,1);
   getmem(p,sizeof(_identblock)*2);
   codiere(p);
   blockwrite(f,p^,sizeof(_identblock)*2);
   freemem(p,sizeof(_identblock)*2);
   close(f);
 end;

 PROCEDURE Ident_ReadDat(fname : string);
  var f : file;
      p,h1 : _byte;
      gr,z1 : word;
      hck1,hck2 : byte;
  begin
   assign(f,fname);
   reset(f,1);
   hck1 := 0;
   hck2 := 0;
   repeat
    if filesize(f)-filepos(f) < $FF00 then gr := filesize(f)-filepos(f)
     else gr := $FF00;
    getmem(p,gr);
    blockread(f,p^,gr);
    h1 := p;
    for z1 := 1 to gr do
    begin
     hck1 := hck1 xor h1^;
     hck2 := hck2 + h1^;
     h1 := ptr(seg(h1^),ofs(h1^)+1);
    end;
    freemem(p,gr);
   until eof(f);
   with identblock do
   begin
    progsize := filesize(f);
    chk1 := hck1;
    chk2 := hck2;
   end;
   close(f);
 end;

 FUNCTION Ident_Teste(fname : string) : boolean;
  var f : file;
      p,h1 : _byte;
      gr,z1 : word;
      hck1,hck2 : byte;
  begin
   assign(f,fname);
   reset(f,1);
   if filesize(f) <> identblock.progsize then falsch := true;
   hck1 := 0;
   hck2 := 0;
   repeat
    if filesize(f)-filepos(f) < $FF00 then gr := filesize(f)-filepos(f)
     else gr := $FF00;
    getmem(p,gr);
    blockread(f,p^,gr);
    h1 := p;
    for z1 := 1 to gr do
    begin
     hck1 := hck1 xor h1^;
     hck2 := hck2 + h1^;
     h1 := ptr(seg(h1^),ofs(h1^)+1);
    end;
    freemem(p,gr);
   until eof(f);
   close(f);
   if hck1 <> identblock.chk1 then falsch := true;
   if hck2 <> identblock.chk2 then falsch := true;
   ident_teste := not falsch;
 end;

 BEGIN
END.