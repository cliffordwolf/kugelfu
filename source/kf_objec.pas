UNIT KF_Objects;

 INTERFACE

 USES VektorBall,KF_Tools,SB_SND;

 TYPE _Ball = object
       x,y,z : integer;
       rad : word;
       col : byte;
       aktiv : boolean;
      end;

      _BewBall = object
       x,y,z : integer;
       vx,vy,vz : integer;
       col : byte;
       rad : word;
       aktiv : boolean;
       CONSTRUCTOR Init;
       PROCEDURE Bewege(rx,ry,rz : integer; steps : word);
       PROCEDURE Put2Cs(_x,_y,_z : integer; var cs : vekball);
       DESTRUCTOR Done;
      end;

      _VBChar = object
       color : byte;
       matrix : array [0..7,0..7] of _ball;
       CONSTRUCTOR Init;
       PROCEDURE setchar(ch : char);
       PROCEDURE put2cs(_x,_y,_z : integer; skal : real; var cs : vekball);
       PROCEDURE RotUmX(a1,a2 : integer);
       DESTRUCTOR Done;
      end;

      _VBString = object
       text : string;
       color : byte;
       zeichen : _vbchar;
       a1,a2 : integer;
       CONSTRUCTOR Init;
       PROCEDURE put2cs(_x,_y,_z : integer; skal : real; var cs : vekball);
       DESTRUCTOR Done;
      end;

      _Enterprise = object
       hcs : array [0..39] of _ball;
       col : byte;
       skal : integer;
       CONSTRUCTOR Init;
       PROCEDURE Drawit;
       DESTRUCTOR Done;
      end;

      _gelenk = record
                 x,y,z : real;
                 tox,toy,toz : real;
                 speedx,speedy,speedz : real;
      end;

      _Fighterorder = record
                        order : integer;
                        op1,op2,op3,op4,op5 : integer;
                       end;
      _Fighterprog = array [0..5460] of _fighterorder;
      __Fighterprog = ^_Fighterprog;
      _PC = record
             IP : word;
             Prog : __Fighterprog;
             Counter : integer;
             Waiter : integer;
            end;
      {******** Befehlssatz **************
       Befehl 0: Halt & Reset Counter+Waiter.

       Befehl 1: setgelenk [op1] [op2,op3,op4] [op5]
                 bei op2 - op4 werden werte
                 Åber 360 durch tox, toy bzw. toz ersetzt!

       Befehl 2: Warte bis Gelenk [op1] die Position [op2,op3,op4]
                 eingenommen hat. Werte Åber 360 werden ignoriert und
                 beeinflussen das Ergebnis in keiner Weise!

       Befehl 3: Springe zu Zeile [op1].

       Befehl 4: Warte [op1] Schritte.

       Befehl 5: Wenn Counter = [op1] dann setze Counter auf null.
                 Wenn Counter <> [op1] dann incrementiere Counter
                 und springe zu Zeile ip+[op2].

       Befehl 6: Setze Gelenk [op1] auf die Position [op2,op3,op4].

       Befehl 7: Addiere zu den Werten von Gelenk [op1] die
                 Werte in [op2,op3,op4] in Zeitspanne [op5].

       Befehl 8: hoehe := [op1]
                 tohoehe := [op2]
                 speedhoehe := ([op2]-[op1])/[op3]

       Befehl 9: Warte bis Hoehe = [op1];

       Befehl 10: Gehe in Position [op1] in [op2] Zeitschritten.

       Befehl 11: Setzte Fixballnr auf [op1].

       Befehl 12: Falle in [op1] Zeitschritten bis zum Boden.
      ***********************************}
      __Fighter = ^_Fighter;
      _Fighter = object
       hcs,rcs : array [0..26] of _ball;
       color : array [1..3] of byte;
       gelenke : array [1..14] of _gelenk;
       hoehe,tohoehe,speedhoehe : real;
       yendrot : real;
       fixballnr : byte;
       pc : _pc;
       xpos,ypos,zpos : integer;
       inx1,iny1,inz1,inx2,iny2,inz2 : integer;
       feind : __Fighter;
       getroffen,energie : byte;
       aktion,altaktion : byte;
       jumperhelp : integer;
       treffermin : byte;
       PROCEDURE SetFlach;
       CONSTRUCTOR Init(x,y,z : integer; p : pointer);
       PROCEDURE Put2Cs(var cs : vekball);
       PROCEDURE Draw;
       PROCEDURE SetGelenk(nr : byte; _x,_y,_z : real; zeit : word);
       PROCEDURE Go;
       PROCEDURE Move;
       PROCEDURE SetFixballnr(nr : byte);
       PROCEDURE Fallen(zeit : integer);
       PROCEDURE SetPos(nr,zeit : integer);
       PROCEDURE SetAktion(ch : char);
      end;

 VAR fx_treffer,fx_vorbei,fx_flatter,fx_beam,fx_bkick : _sample;

 PROCEDURE Load_Chars(n : string);


 IMPLEMENTATION

 TYPE _ChMap = record
       map : array [0..7] of byte;
       yver : integer;
      end;

 CONST fname : string = 'vektchar.dat';

       _1fighter : array [1..26] of array [1..5] of integer =
                   ((0,160,0,20,3),
                    (0,130,0,10,1),
                    (0,80,0,40,1),
                    (0,0,0,40,1),

                    (-50,110,0,10,1),
                    (-50,90,0,10,2),
                    (-50,70,0,10,2),
                    (-50,50,0,10,2),
                    (-50,30,0,10,2),

                    (50,110,0,10,1),
                    (50,90,0,10,2),
                    (50,70,0,10,2),
                    (50,50,0,10,2),
                    (50,30,0,10,2),

                    (-30,-40,0,10,1),
                    (-30,-60,0,10,1),
                    (-30,-80,0,10,1),
                    (-30,-100,0,10,1),
                    (-30,-120,0,10,1),
                   
                    (30,-40,0,10,1),
                    (30,-60,0,10,1),
                    (30,-80,0,10,1),
                    (30,-100,0,10,1),
                    (30,-120,0,10,1),

                    (-30,115,0,5,1),
                    (30,115,0,5,1));

       Fighterpos : array [0..3] of array [1..11,1..3] of integer =
                  (((0,0,0),
                    (0,0,0),
                    (0,0,0),
                    (0,0,0),
                    (0,0,0),
                    (0,0,0),
                    (0,0,0),
                    (0,0,0),
                    (0,0,0),
                    (0,0,0),
                    (0,0,0)),
                   ((0,0,0),
                    (100,20,0),
                    (65,0,0),
                    (60,0,0),
                    (40,0,0),
                    (60,20,0),
                    (60,0,0),
                    (60,0,0),
                    (30,10,0),
                    (10,20,0),
                    (0,-40,0)),
                   ((50,0,0),
                    (490,0,0),
                    (0,0,0),
                    (135,0,0),
                    (90,0,0),
                    (90,0,0),
                    (0,0,0),
                    (135,0,0),
                    (90,0,0),
                    (45,0,0),
                    (0,0,0)),
                   ((-15,0,0),
                    (5,0,0),
                    (50,-90,0),
                    (90,0,0),
                    (12,0,0),
                    (0,0,0),
                    (15,90,0),
                    (0,0,0),
                    (20,90,0),
                    (0,0,0),
                    (-90,0,0)));

 CONST Anf : array [0..1] of array [1..6] of integer =
              ((10,1,5,0,0,0),
               (0,0,0,0,0,0));

       Kick1 : array [0..22] of array [1..6] of integer =
              ((1,5,90,0,0,3),
               (1,4,45,0,0,3),
               (1,9,0,0,0,6),
               (1,8,0,0,0,6),
               (7,11,0,45,0,1),
               (4,1,0,0,0,0),
               (5,3,-2,0,0,0),
               (1,4,0,0,0,3),
               (7,11,0,45,0,1),
               (4,1,0,0,0,0),
               (5,3,-2,0,0,0),
               (6,11,0,0,0,0),
               (7,11,0,45,0,1),
               (4,1,0,0,0,0),
               (5,4,-2,0,0,0),
               (1,11,0,0,0,3),
               (1,4,20,0,0,1),
               (7,11,0,45,0,1),
               (2,4,20,0,0,0),
               (6,11,0,-45,0,1),
               (10,1,3,0,0,0),
               (4,3,0,0,0,0),
               (0,0,0,0,0,0));

       Kick2 : array [0..7] of array [1..6] of integer =
              ((10,0,2,0,0,0),
               (1,5,135,20,0,2),
               (1,4,45,0,0,1),
               (4,1,0,0,0,0),
               (1,4,0,0,0,1),
               (4,1,0,0,0,0),
               (10,1,2,0,0,0),
               (0,0,0,0,0,0));

       Feger : array [0..22] of array [1..6] of integer =
              ((1,5,90,0,0,3),
               (1,4,45,0,0,3),
               (1,9,80,0,0,6),
               (1,8,160,0,0,6),
               (7,11,0,45,0,1),
               (4,1,0,0,0,0),
               (5,3,-2,0,0,0),
               (1,4,0,0,0,3),
               (7,11,0,45,0,1),
               (4,1,0,0,0,0),
               (5,3,-2,0,0,0),
               (6,11,0,0,0,0),
               (7,11,0,45,0,1),
               (4,1,0,0,0,0),
               (5,4,-2,0,0,0),
               (1,11,0,0,0,3),
               (1,4,20,0,0,1),
               (7,11,0,45,0,1),
               (2,4,20,0,0,0),
               (6,11,0,-45,0,1),
               (10,1,3,0,0,0),
               (4,3,0,0,0,0),
               (0,0,0,0,0,0));

       Jump1 : array [0..42] of array [1..6] of integer =
              ((1,5,72,0,0,5),
               (1,4,144,0,0,5),
               (1,9,72,0,0,5),
               (1,8,144,0,0,5),
               (1,10,48,0,0,5),
               (1,3,32,0,0,5),
               (1,7,32,0,0,5),
               (1,2,72,0,0,5),
               (1,6,72,0,0,5),
               (1,11,0,0,0,5),
               (2,8,144,0,0,0),
               (4,2,0,0,0,0),
               (10,0,3,0,0,0),
               (2,8,0,0,0,0),
               (11,3,0,0,0,0),
               (7,12,0,300,0,7),
               (10,2,3,0,0,0),
               (4,3,0,0,0,0),
               (1,11,180,0,0,4),
               (4,4,0,0,0,0),
               (6,11,-180,0,0,0),
               (1,11,0,0,0,4),
               (7,12,0,-300,0,7),
               (4,4,0,0,0,0),
               (10,0,3,0,0,0),
               (4,3,0,0,0,0),
               (11,24,0,0,0,0),
               (10,2,3,0,0,0),
               (4,2,0,0,0,0),
               (10,1,3,0,0,0),
               (4,3,0,0,0,0),
               (0,0,0,0,0,0),
               (10,2,2,0,0,0),
               (1,1,0,0,0,2),
               (1,4,20,0,0,2),
               (1,8,20,0,0,2),
               (1,11,-60,0,0,2),
               (4,1,0,0,0,0),
               (12,3,0,0,0,0),
               (5,2,-2,0,0,0),
               (11,24,0,0,0,0),
               (4,4,0,0,0,0),
               (0,0,0,0,0,0));



       Treffer1 : array [0..4] of array [1..6] of integer =
              ((1,10,-10,60,0,2),
               (1,1,-20,0,0,2),
               (4,2,0,0,0,0),
               (10,1,2,0,0,0),
               (0,0,0,0,0,0));

       Treffer2 : array [0..13] of array [1..6] of integer =
              ((6,13,0,0,0,0),
               (11,3,0,0,0,0),
               (10,3,10,0,0,0),
               (7,12,-20,5,0,1),
               (4,1,0,0,0,0),
               (11,4,0,0,0,0),
               (5,5,-3,0,0,0),
               (7,12,-20,0,0,1),
               (12,3,0,0,0,0),
               (4,1,0,0,0,0),
               (5,10,-3,0,0,0),
               (11,24,0,0,0,0),
               (4,10,0,0,0,0),
               (0,0,0,0,0,0));

       Schritt_R : array [0..8] of array [1..6] of integer =
              ((1,11,0,0,0,3),
               (1,10,10,0,0,3),
               (2,11,0,0,0,0),
               (11,19,0,0,0,0),
               (10,1,3,0,0,0),
               (2,10,10,20,0,0),
               (11,24,0,0,0,0),
               (1,12,5000,5000,0,1),
               (0,0,0,0,0,0));

       Schritt_L : array [0..8] of array [1..6] of integer =
              ((1,11,0,0,0,3),
               (1,10,10,0,0,3),
               (11,19,0,0,0,0),
               (2,11,0,0,0,0),
               (11,24,0,0,0,0),
               (10,1,3,0,0,0),
               (2,10,10,20,0,0),
               (1,12,5000,5000,0,1),
               (0,0,0,0,0,0));

       Punchen : array [0..7] of array [1..6] of integer =
              ((1,6,175,0,0,2),
               (1,7,5,0,0,2),
               (1,3,120,-80,0,2),
               (1,2,0,0,0,2),
               (1,10,20,135,0,2),
               (4,2,0,0,0,0),
               (10,1,2,0,0,0),
               (0,0,0,0,0,0));

       Special1 : array [0..20] of array [1..6] of integer =
              ((10,2,5,0,0,0),
               (4,2,0,0,0,0),
               (13,0,0,0,0,0),
               (4,1,0,0,0,0),
               (10,0,2,0,0,0),
               (1,3,-10,0,0,2),
               (1,7,-10,0,0,2),
               (1,1,-10,0,0,2),
               (4,2,0,0,0,0),
               (11,3,0,0,0,0),
               (7,12,0,30,0,3),
               (1,11,-180,0,0,3),
               (4,3,0,0,0,0),
               (10,2,5,0,0,0),
               (7,12,0,-30,0,3),
               (1,11,-360,0,0,3),
               (4,3,0,0,0,0),
               (6,11,0,0,0,0),
               (11,24,0,0,0,0),
               (10,1,2,0,0,0),
               (0,0,0,0,0,0));

       Special2 : array [0..13] of array [1..6] of integer =
              ((10,0,3,0,0,0),
               (1,2,45,0,0,3),
               (1,3,90,90,0,3),
               (1,6,45,0,0,3),
               (1,7,90,90,0,3),
               (4,5,0,0,0,0),
               (7,13,1500,0,0,6),
               (4,6,0,0,0,0),
               (7,13,-3000,0,0,1),
               (4,1,0,0,0,0),
               (1,13,0,0,0,6),
               (4,6,0,0,0,0),
               (10,1,3,0,0,0),
               (0,0,0,0,0,0));

       Special3 : array [0..10] of array [1..6] of integer =
              ((10,0,2,0,0,0),
               (1,3,90,-90,0,2),
               (1,7,90,90,0,2),
               (1,10,0,180,0,4),
               (4,4,0,0,0,0),
               (6,10,0,-180,0,0),
               (1,10,0,0,0,4),
               (4,2,0,0,0,0),
               (10,1,2,0,0,0),
               (4,2,0,0,0,0),
               (0,0,0,0,0,0));

       Decken : array [0..11] of array [1..6] of integer =
              ((10,1,2,0,0,0),
               (1,10,0,0,0,2),
               (1,3,100,0,0,2),
               (1,2,80,20,0,2),
               (1,7,50,0,0,2),
               (1,6,70,-80,0,2),
               (1,4,90,0,0,2),
               (1,5,0,0,0,2),
               (1,8,90,0,0,2),
               (1,9,45,10,0,2),
               (1,11,0,0,0,2),
               (0,0,0,0,0,0));

       Runter : array [0..3] of array [1..6] of integer =
              ((10,2,2,0,0,0),
               (1,10,80,0,0,2),
               (1,1,30,0,0,2),
               (0,0,0,0,0,0));

       Normal : array [0..4] of array [1..6] of integer =
              ((10,1,3,0,0,0),
               (1,13,0,0,0,3),
               (1,14,1,1,1,3),
               (11,24,0,0,0,0),
               (0,0,0,0,0,0));

       Beam : array [0..10] of array [1..6] of integer =
              ((11,1,0,0,0,0),
               (7,12,+300,+800,0,3),
               (1,14,15,15,15,3),
               (4,3,0,0,0,0),
               (7,12,+200,0,0,2),
               (4,2,0,0,0,0),
               (7,12,+300,-800,0,3),
               (1,14,1,1,1,3),
               (4,3,0,0,0,0),
               (11,24,0,0,0,0),
               (0,0,0,0,0,0));

 VAR  fdata : array [0..255] of _chmap;


 CONSTRUCTOR _BewBall.Init;
  begin
   x := 0;
   y := 0;
   z := 0;
   vx := 0;
   vy := 0;
   vz := 0;
   col := 0;
   rad := 0;
   aktiv := false;
 end;

 PROCEDURE _BewBall.Bewege(rx,ry,rz : integer; steps : word);
  begin
   while steps > 0 do
   begin
    vx := vx+rx;
    vy := vy+ry;
    vz := vz+rz;
    x := x+vx;
    y := y+vy;
    z := z+vz;
    dec(steps);
   end;
 end;

 PROCEDURE _BewBall.Put2Cs(_x,_y,_z : integer; var cs : vekball);
  begin
   if aktiv then cs.add(x+_x,y+_y,z+_z,rad,col);
 end;

 DESTRUCTOR _BewBall.Done;
  begin
 end;

 CONSTRUCTOR _VBChar.Init;
  var zx,zy : byte;
  begin
   for zx := 0 to 7 do
   for zy := 0 to 7 do
   with matrix[zx,zy] do
   begin
    x := zx*2-7;
    y := zy*2-7;
    z := 0;
    rad := 1;
    col := 0;
    aktiv := false;
   end;
 end;

 PROCEDURE _VBChar.setchar(ch : char);
  var hm : array [0..7] of byte;
      zx,zy : byte;
  begin
   ch := upcase(ch);
   for zy := 0 to 7 do
    hm[zy] := fdata[ord(ch)].map[zy];

   for zx := 0 to 7 do
   for zy := 0 to 7 do
   with matrix[zx,zy] do
   begin
    x := zx*2-7;
    y := zy*2-7;
    z := 0;
    col := color;
    rad := 1;
    aktiv := false;
    if (hm[zy] shr zx) and 1 = 1 then aktiv := true;
   end;
 end;

 PROCEDURE _VBChar.put2cs(_x,_y,_z : integer; skal : real; var cs : vekball);
  var zx,zy : byte;
  begin
   for zx := 0 to 7 do
   for zy := 0 to 7 do
   with matrix[zx,zy] do
   if aktiv then
   begin
    cs.add(round(x*skal)+_x,round(y*skal)+_y,round(z*skal)+_z,round(rad*skal),col);
   end;
 end;

 PROCEDURE _VBChar.RotUmX(a1,a2 : integer);
  var zx,zy : byte;
      ha : integer;
  begin
   for zx := 0 to 7 do
   begin
    ha := (a1*(7-zx)+a2*zx) div 7;
    ha := ha mod 360;
    if ha < 0 then ha := 360-abs(ha);
    for zy := 0 to 7 do
     with matrix[zx,zy] do
     if aktiv then
     begin
      z := x_rot(y,ha);
      y := y_rot(y,ha);
     end;
   end;
 end;

 DESTRUCTOR _VBChar.Done;
  begin
 end;

 CONSTRUCTOR _VBString.Init;
  begin
   text := '';
   a1 := 90;
   a2 := 90;
 end;

 PROCEDURE _VBString.put2cs(_x,_y,_z : integer; skal : real; var cs : vekball);
  var z1,ln,hx,hr : integer;
      ha : real;
  begin
   zeichen.init;
   ln := length(text);
   for z1 := 1 to ln do
   begin
    ha := (a2-a1)/ln;
    hx := round((-10*(ln-1)+(z1-1)*20)*skal)+_x;
    hr := round(10*skal);
    if cs.inscr(hx-hr,_y-hr,_z-hr,hx+hr,_y+hr,_z+hr) then
    begin
     zeichen.color := color;
     zeichen.setchar(text[z1]);
     zeichen.rotumx(round(a1+ha*(z1-1)),round(a1+ha*z1));
     zeichen.put2cs(hx,_y,_z,skal,cs);
    end;
   end;
   zeichen.done;
 end;

 DESTRUCTOR _VBString.Done;
  begin
 end;

 CONSTRUCTOR _Enterprise.Init;
  begin
 end;

 PROCEDURE _Enterprise.Drawit;
  var z1 : integer;
      hx,hy,hz : integer;
      _hx,_hy,_hz : integer;
      hc : byte;
  begin
   hc := col;
   with hcs[0] do
   begin
    rad := 15;
    col := hc;
    x := 0;
    y := 0;
    z := 0;
    aktiv := true;
   end;
   for z1 := 1 to 6 do
   with hcs[z1] do
   begin
    rad := 10;
    col := hc;
    x := x_rot(25,(z1-1)*60);
    y := 0;
    z := y_rot(25,(z1-1)*60);
    aktiv := true;
   end;
   for z1 := 7 to 16 do
   with hcs[z1] do
   begin
    rad := 10;
    col := hc;
    x := x_rot(45,(z1-1)*36);
    y := 0;
    z := y_rot(45,(z1-1)*36);
    aktiv := true;
   end;
   hx := x_rot(20,45);
   hy := y_rot(20,45);
   hz := 0;
   for z1 := 17 to 21 do
   with hcs[z1] do
   begin
    rad := 5;
    col := hc;
    x := hx;
    y := hy;
    z := hz;
    aktiv := true;
    hx := hx+x_rot(10,45);
    hy := hy+y_rot(10,45);
   end;
   hx := hx+x_rot(5,45);
   hy := hy+y_rot(5,45);
   for z1 := 22 to 25 do
   with hcs[z1] do
   begin
    rad := 10;
    col := hc;
    x := hx+(z1-22)*20;
    y := hy;
    z := hz;
    aktiv := true;
   end;
   _hx := hx+60;
   _hy := hy;
   _hz := hz;
   hx := _hx;
   hy := _hy+y_rot(5,225);
   hz := _hz+x_rot(5,225);
   for z1 := 26 to 28 do
   with hcs[z1] do
   begin
    rad := 5;
    col := hc;
    hx := hx;
    hy := hy+y_rot(10,225);
    hz := hz+x_rot(10,225);
    x := hx;
    y := hy;
    z := hz;
    aktiv := true;
   end;
   hy := hy+y_rot(15,225);
   hz := hz+y_rot(15,225);
   for z1 := 29 to 32 do
   with hcs[z1] do
   begin
    rad := 10;
    col := hc;
    x := hx;
    y := hy;
    z := hz;
    hx := hx+20;
    aktiv := true;
   end;
   hx := _hx;
   hy := _hy+y_rot(5,225);
   hz := _hz-x_rot(5,225);
   for z1 := 33 to 35 do
   with hcs[z1] do
   begin
    rad := 5;
    col := hc;
    hx := hx;
    hy := hy+y_rot(10,225);
    hz := hz-x_rot(10,225);
    x := hx;
    y := hy;
    z := hz;
    aktiv := true;
   end;
   hy := hy+y_rot(15,225);
   hz := hz-y_rot(15,225);
   for z1 := 36 to 39 do
   with hcs[z1] do
   begin
    rad := 10;
    col := hc;
    x := hx;
    y := hy;
    z := hz;
    hx := hx+20;
    aktiv := true;
   end;
   for z1 := 0 to 39 do
   with hcs[z1] do
   begin
    x := (x*skal) div 5;
    y := (y*skal) div 5;
    z := (z*skal) div 5;
    rad := (rad*skal div 5);
   end;
 end;

 DESTRUCTOR _Enterprise.Done;
  begin
 end;

 PROCEDURE _Fighter.SetFlach;
  var z1 : byte;
  begin
   for z1 := 1 to 26 do
   with hcs[z1] do
   begin
    x := _1fighter[z1,1];
    y := _1fighter[z1,2];
    z := _1fighter[z1,3];
    rad := _1fighter[z1,4];
    col := _1fighter[z1,5];
    aktiv := true;
   end;
 end;

 CONSTRUCTOR _Fighter.Init(x,y,z : integer; p : pointer);
  var z1 : byte;
  begin
   feind := p;
   getroffen := 0;
   energie := 100;
   xpos := x;
   ypos := y;
   zpos := z;
   inx1 := x;
   iny1 := y;
   inz1 := z;
   inx2 := x;
   iny2 := y;
   inz2 := z;
   for z1 := 1 to 13 do
   with gelenke[z1] do
   begin
    x := 0;
    y := 0;
    z := 0;
    tox := 0;
    toy := 0;
    toz := 0;
    speedx := 0;
    speedy := 0;
    speedz := 0;
   end;
   with gelenke[14] do
   begin
    x := 1;
    y := 1;
    z := 1;
    tox := 1;
    toy := 1;
    toz := 1;
    speedx := 0;
    speedy := 0;
    speedz := 0;
   end;
   hoehe := 0;
   tohoehe := 0;
   speedhoehe := 0;
   for z1 := 1 to 3 do color[z1] := 0;
   pc.ip := 0;
   pc.prog := addr(anf);
   pc.counter := 0;
   pc.waiter := 0;
   aktion := 0;
   altaktion := 100;
   yendrot := 0;
   fixballnr := 4;
   setflach;
 end;

 PROCEDURE _Fighter.Draw;
  var z1 : integer;
  begin
   setflach;

  with hcs[1] do
  begin
   y := y-130;
   rotumy(x,y,z,gelenke[1].y);
   rotumx(x,y,z,360-gelenke[1].x);
   rotumz(x,y,z,gelenke[1].z);
   y := y+130;
  end;
   for z1 := 1 to 2 do
   with hcs[z1] do
   begin
    y := y-80;
    rotumy(x,y,z,gelenke[1].y);
    rotumx(x,y,z,360-gelenke[1].x);
    rotumz(x,y,z,gelenke[1].z);
    y := y+80;
   end;

   for z1 := 8 to 9 do
   with hcs[z1] do
   begin
    x := x+50;
    y := y-70;
    rotumx(x,y,z,gelenke[2].x);
    rotumy(x,y,z,gelenke[2].y);
    x := x-50;
    y := y+70;
   end;
   for z1 := 6 to 9 do
   with hcs[z1] do
   begin
    x := x+50;
    y := y-110;
    rotumx(x,y,z,gelenke[3].x);
    rotumy(x,y,z,gelenke[3].y);
    x := x-50;
    y := y+110;
   end;

   for z1 := 18 to 19 do
   with hcs[z1] do
   begin
    x := x+30;
    y := y+80;
    rotumx(x,y,z,360-gelenke[4].x);
    rotumy(x,y,z,gelenke[4].y);
    x := x-30;
    y := y-80;
   end;
   for z1 := 15 to 19 do
   with hcs[z1] do
   begin
    rotumx(x,y,z,gelenke[5].x);
    rotumy(x,y,z,gelenke[5].y);
   end;

   for z1 := 13 to 14 do
   with hcs[z1] do
   begin
    x := x-50;
    y := y-70;
    rotumx(x,y,z,gelenke[6].x);
    rotumy(x,y,z,gelenke[6].y);
    x := x+50;
    y := y+70;
   end;
   for z1 := 11 to 14 do
   with hcs[z1] do
   begin
    x := x-50;
    y := y-110;
    rotumx(x,y,z,gelenke[7].x);
    rotumy(x,y,z,gelenke[7].y);
    x := x+50;
    y := y+110;
   end;

   for z1 := 23 to 24 do
   with hcs[z1] do
   begin
    x := x-30;
    y := y+80;
    rotumx(x,y,z,360-gelenke[8].x);
    rotumy(x,y,z,gelenke[8].y);
    x := x+30;
    y := y-80;
   end;
   for z1 := 20 to 24 do
   with hcs[z1] do
   begin
    rotumx(x,y,z,gelenke[9].x);
    rotumy(x,y,z,gelenke[9].y);
   end;

   for z1 := 1 to 26 do
   begin
    if z1 = 15 then z1 := 25;
    with hcs[z1] do
    begin
     rotumy(x,y,z,gelenke[10].y);
     rotumx(x,y,z,360-gelenke[10].x);
     rotumz(x,y,z,gelenke[10].z);
    end;
   end;

   for z1 := 1 to 26 do
   with hcs[z1] do
   begin
    rotumx(x,y,z,360-gelenke[11].x);
    rotumz(x,y,z,gelenke[11].z);
    rotumy(x,y,z,gelenke[11].y+90);
   end;

   with gelenke[13] do
    begin
     hcs[4].x := hcs[4].x+round(x);
     hcs[4].y := hcs[4].y+round(y);
     hcs[4].z := hcs[4].z+round(z);
   end;

   if yendrot <> 90 then
    for z1 := 1 to 26 do
     with hcs[z1] do x := -x;
 end;

 PROCEDURE _Fighter.SetGelenk(nr : byte; _x,_y,_z : real; zeit : word);
  begin
   with gelenke[nr] do
   begin
    tox := _x;
    speedx := (_x-x)/zeit;
    toy := _y;
    speedy := (_y-y)/zeit;
    toz := _z;
    speedz := (_z-z)/zeit;
   end;
 end;

 PROCEDURE _Fighter.Go;
  var z1 : byte;
  procedure step(var a : real; toa,speed : real);
   begin
    if abs(a-toa) < abs(speed) then a := toa
     else a := a+speed;
  end;
  begin
   gelenke[12].tox := gelenke[12].tox-gelenke[12].x;
   xpos := round(xpos+gelenke[12].x);
   gelenke[12].x := 0;
   for z1 := 1 to 14 do
   with gelenke[z1] do
   begin
    step(x,tox,speedx);
    step(y,toy,speedy);
    step(z,toz,speedz);
   end;
   step(hoehe,tohoehe,speedhoehe);
 end;

 PROCEDURE _Fighter.Setfixballnr(nr : byte);
  var hx,hy,hz : integer;
  begin
   with hcs[fixballnr] do
   begin
    hx := x;
    hy := y;
    hz := z;
   end;
   fixballnr := nr;
   with hcs[fixballnr] do
   begin
    hx := x-hx;
    hy := y-hy;
    hz := z-hz;
   end;
   with gelenke[12] do
   begin
    x := x+hx;
    y := y+hy;
    z := z+hz;
    tox := tox+hx;
    toy := toy+hy;
    toz := toz+hz;
   end;
 end;

 PROCEDURE _Fighter.Fallen(zeit : integer);
  var h1,z1,hy : integer;
  begin
   hy := hcs[fixballnr].y;
   h1 := hcs[1].y-hcs[1].rad;
   for z1 := 1 to 26 do
    with hcs[z1] do
     if h1 > (y-rad) then h1 := y-rad;
   with gelenke[12] do
    setgelenk(12,tox,hy-h1,toz,zeit);
 end;

 PROCEDURE _Fighter.SetPos(nr,zeit : integer);
  var z1 : integer;
  begin
   for z1 := 1 to 11 do setgelenk(z1,fighterpos[nr,z1,1],fighterpos[nr,z1,2],fighterpos[nr,z1,3],zeit);
 end;

 PROCEDURE _Fighter.Move;
  var h1,h2,h3 : real;
      ende : boolean;
      z1 : integer;
  begin
   repeat
    ende := true;
    with pc do
    with prog^[ip] do
    case order of
     0 : begin
          counter := 0;
          waiter := 0;
          fallen(1);
         end;
     1 : with gelenke[op1] do
         begin
          h1 := op2;
          if h1 > 1000 then h1 := tox;
          h2 := op3;
          if h2 > 1000 then h2 := toy;
          h3 := op4;
          if h3 > 1000 then h3 := toz;
          setgelenk(op1,h1,h2,h3,op5);
          ende := false;
          inc(ip);
         end;
     2 : with gelenke[op1] do
         begin
          ende := false;
          if (op2 <> x) and (op2 <= 1000) then ende := true;
          if (op3 <> y) and (op2 <= 1000) then ende := true;
          if (op4 <> z) and (op2 <= 1000) then ende := true;
          if not ende then inc(ip);
         end;
     3 : begin
          ip := op1;
          ende := false;
         end;
     4 : begin
          inc(waiter);
          if waiter > op1 then
          begin
           inc(ip);
           ende := false;
           waiter := 0;
          end;
         end;
     5 : begin
          ende := false;
          inc(ip);
          inc(counter);
          if counter > op1 then counter := 0
           else ip := ip+op2-1;
         end;
     6 : with gelenke[op1] do
         begin
          ende := false;
          tox := op2;
          x := op2;
          toy := op3;
          y := op3;
          toz := op4;
          z := op4;
          inc(ip);
         end;
     7 : with gelenke[op1] do
         begin
          ende := false;
          if (op1 = 12) and (yendrot <> 90) then setgelenk(op1,x-op2,op3+y,op4+z,op5)
           else setgelenk(op1,x+op2,y+op3,z+op4,op5);
          inc(ip);
         end;
     8 : begin
          ende := false;
          hoehe := op1;
          tohoehe := op2;
          speedhoehe := (op2-op1)/op3;
          inc(ip);
         end;
     9 : if hoehe = op1 then
         begin
          inc(ip);
          ende := false;
         end;
     10 : begin
           setpos(op1,op2);
           inc(ip);
           ende := false;
          end;
     11 : begin
           setfixballnr(op1);
           inc(ip);
           ende := false;
          end;
     12 : begin
           fallen(op1);
           inc(ip);
           ende := false;
          end;
     13 : begin
           for z1 := 1 to 11 do
           with gelenke[z1] do
           begin
            tox := x;
            toy := y;
            toz := z;
           end;
           inc(ip);
           ende := false;
          end;
    end;
   until ende;
 end;

 PROCEDURE _Fighter.SetAktion(ch : char);

  VAR h1 : integer;

  FUNCTION Beruehrt : boolean;
   begin
    beruehrt := true;
    if not((inx2 > feind^.inx1) and (inx1 < feind^.inx2)) then beruehrt := false;
    if not((iny2 > feind^.iny1) and (iny1 < feind^.iny2)) then beruehrt := false;
    if not((inz2 > feind^.inz1) and (inz1 < feind^.inz2)) then beruehrt := false;
  end;

  PROCEDURE SetMove(p : pointer);
   begin
    pc.ip := 0;
    pc.prog := p;
    pc.counter := 0;
    pc.waiter := 0;
  end;

  PROCEDURE Nichts;
   begin
    if altaktion <> aktion then setmove(addr(Normal));
    altaktion := aktion;
    if ch = ' ' then
     if yendrot = 90 then yendrot := 270 else yendrot := 90;
    if (ch in ['4','6']) and (yendrot <> 90) then
     if ch = '4' then ch := '6' else ch := '4';
    case ch of
     '5' : aktion := 1;
     '0' : aktion := 2;
     '-' : aktion := 4;
     '2' : aktion := 5;
     '+' : aktion := 6;
     '1' : aktion := 7;
     '*' : aktion := 8;
     '3' : aktion := 9;
     '/' : aktion := 10;
     ',' : aktion := 11;
     '6' : aktion := 13;
     '4' : aktion := 14;
    end;
    if ch in ['7','8','9'] then
    begin
     aktion := 12;
     jumperhelp := 0;
     case ch of
      '7' : jumperhelp := -50;
      '9' : jumperhelp := 50;
     end;
    end;
  end;

  PROCEDURE Deckung;
   begin
    if altaktion <> aktion then setmove(addr(Decken));
    altaktion := aktion;
    if ch = ' ' then
     if yendrot = 90 then yendrot := 270 else yendrot := 90;
    if (ch in ['4','6']) and (yendrot <> 90) then
     if ch = '4' then ch := '6' else ch := '4';
    case ch of
     chr(13) : aktion := 0;
     '0' : aktion := 2;
     '-' : aktion := 4;
     '2' : aktion := 5;
     '+' : aktion := 6;
     '1' : aktion := 7;
     '*' : aktion := 8;
     '3' : aktion := 9;
     '/' : aktion := 10;
     ',' : aktion := 11;
     '6' : aktion := 13;
     '4' : aktion := 14;
    end;
    if ch in ['7','8','9'] then
    begin
     aktion := 12;
     jumperhelp := 0;
     case ch of
      '7' : jumperhelp := -50;
      '9' : jumperhelp := 50;
     end;
    end;
  end;

  PROCEDURE Ducken;
   begin
    if altaktion <> aktion then setmove(addr(Runter));
    altaktion := aktion;
    case ch of
     chr(13) : aktion := 0;
     '3' : aktion := 9;
     '5' : aktion := 1;
     ',' : aktion := 11;
    end;
  end;

  PROCEDURE AmHintern;
   begin
    if beruehrt and (pc.ip < 42) then
    begin
     aktion := 0;
     feind^.getroffen := 2;
    end;
    if (ch = chr(13)) and (pc.ip = 42) then aktion := 0;
  end;

  PROCEDURE Punch;
   begin
    if altaktion <> aktion then setmove(addr(punchen));
    altaktion := aktion;
    if beruehrt and (pc.ip = 5) and (pc.waiter = 2)
       and (feind^.aktion <> 2) then feind^.getroffen := 1;
    if ((not beruehrt) or (not (feind^.aktion <>2))) and (pc.ip = 5)
       and (pc.waiter = 2) and sbready then wiedergabe(fx_vorbei);
    if pc.ip = 7 then aktion := 0;
  end;

  PROCEDURE Kick;
   begin
    if altaktion <> aktion then setmove(addr(kick2));
    altaktion := aktion;
    if beruehrt and (pc.ip = 5) then feind^.getroffen := 1;
    if (not beruehrt) and (pc.ip = 5) and sbready then wiedergabe(fx_vorbei);
    if pc.ip = 7 then aktion := 0;
  end;

  PROCEDURE Drehkick;
   begin
    if altaktion <> aktion then setmove(addr(kick1));
    altaktion := aktion;
    if beruehrt and (pc.ip in [13..16]) and (feind^.aktion <> 2) then feind^.getroffen := 3;
    if ((not beruehrt) or (feind^.aktion <> 2))
       and (pc.ip in [13..16]) and sbready then wiedergabe(fx_vorbei);
    if pc.ip = 22 then aktion := 0;
  end;

  PROCEDURE Fegen;
   begin
    if altaktion <> aktion then setmove(addr(feger));
    altaktion := aktion;
    if beruehrt and (pc.ip in [13..16]) then feind^.getroffen := 3;
    if (not beruehrt) and (pc.ip in [13..16]) and sbready then wiedergabe(fx_vorbei);
    if pc.ip = 22 then aktion := 0;
  end;

  PROCEDURE Spirale;
   begin
    if altaktion <> aktion then setmove(addr(special3));
    altaktion := aktion;
    if beruehrt and (((pc.ip = 4)
       and (pc.waiter >= 2)) or (pc.ip = 7))
       and (feind^.aktion <> 2) then feind^.getroffen := 2;
    if ((not beruehrt) or (feind^.aktion <> 2))
       and (((pc.ip = 4) and (pc.waiter >= 2)) or (pc.ip = 7))
       and sbready then wiedergabe(fx_vorbei);
    if pc.ip = 10 then aktion := 0;
  end;

  PROCEDURE Kick360;
   begin
    if altaktion <> aktion then setmove(addr(special1));
    altaktion := aktion;
    if beruehrt and (pc.ip in [12..15]) then feind^.getroffen := 2;
    if (not beruehrt) and (pc.ip in [12..15]) and sbready then wiedergabe(fx_vorbei);
    if pc.ip = 20 then aktion := 0;
  end;

  PROCEDURE Bauchkick;
   begin
    if altaktion <> aktion then setmove(addr(special2));
    altaktion := aktion;
    if (rcs[4].x < feind^.inx2+100) and (rcs[4].x > feind^.inx1-100)
       and (rcs[4].y < feind^.iny2) and (rcs[4].y > feind^.iny1)
       and (feind^.aktion <> 2) then feind^.getroffen := 4;
    if pc.ip = 13 then aktion := 0;
    if (pc.ip = 7) and (pc.waiter = 1) then wiedergabe(fx_bkick);
  end;

  PROCEDURE Beamen;
   begin
    if altaktion <> aktion then
    begin
     setmove(addr(beam));
     wiedergabe(fx_beam);
    end;
    altaktion := aktion;
    if pc.ip = 10 then aktion := 0;
  end;

  PROCEDURE Sprung;
   begin
    if altaktion <> aktion then setmove(addr(jump1));
    altaktion := aktion;
    if ch = '+' then
    begin
     pc.ip := 32;
    end;
    if pc.ip in [15..23,35..39] then
    with gelenke[12] do
    begin
     x := x+jumperhelp;
     tox := tox+jumperhelp;
    end;
    if pc.ip = 31 then aktion := 0;
    if pc.ip = 37 then aktion := 3;
    if (pc.ip in [17..25]) and sbready then wiedergabe(fx_flatter);
  end;

  PROCEDURE SchrittR;
   begin
    if altaktion <> aktion then setmove(addr(schritt_r));
    altaktion := aktion;
    if ord(ch) in [42..45,47..57] then
    if not (ch in ['4','6']) then
    begin
     aktion := 0;
     nichts;
    end;
    if pc.ip = 8 then aktion := 0;
  end;

  PROCEDURE SchrittL;
   begin
    if altaktion <> aktion then setmove(addr(schritt_l));
    altaktion := aktion;
    if ord(ch) in [42..45,47..57] then
    if not (ch in ['4','6']) then
    begin
     aktion := 0;
     nichts;
    end;
    if pc.ip = 8 then aktion := 0;
  end;

  PROCEDURE Treffer;
   begin
    if getroffen > 0 then energie := energie-getroffen-treffermin;
    if altaktion <> aktion then
    begin
     wiedergabe(fx_treffer);
     setmove(addr(treffer1));
    end;
    altaktion := aktion;
    setgelenk(13,0,0,0,1);
    setgelenk(14,1,1,1,1);
    getroffen := 0;
    if pc.ip = 4 then aktion := 0;
  end;

  PROCEDURE Sturz;
   begin
    if getroffen > 0 then energie := energie-getroffen-treffermin;
    if altaktion <> aktion then
    begin
     setmove(addr(treffer2));
     wiedergabe(fx_treffer);
    end;
    altaktion := aktion;
    setgelenk(13,0,0,0,1);
    setgelenk(14,1,1,1,1);
    getroffen := 0;
    if (pc.ip in [12,13]) and (ord(ch) = 13) then aktion := 0;
  end;

  PROCEDURE Tot;
   begin
    if getroffen > 0 then energie := 0;
    getroffen := 0;
    energie := 0;
    if altaktion <> aktion then
    begin
     setmove(addr(treffer2));
     wiedergabe(fx_treffer);
    end;
    altaktion := aktion;
    setgelenk(13,0,0,0,1);
    setgelenk(14,1,1,1,1);
  end;

  BEGIN
   h1 := getroffen;
   if ((feind^.inx2-feind^.inx1) div 2 + feind^.inx1 > (inx2-inx1) div 2 + inx1)
      and (yendrot <> 90) and (aktion in [0..1]) then ch := ' ';
   if ((feind^.inx2-feind^.inx1) div 2 + feind^.inx1 < (inx2-inx1) div 2 + inx1)
      and (yendrot <> 270) and (aktion in [0..1]) then ch := ' ';
   if (getroffen = 1) and (aktion <> 1) then aktion := 15;
   if (getroffen = 2) and (aktion <> 1) then aktion := 15;
   if (getroffen = 1) and (aktion = 1) then getroffen := 0;
   if (getroffen = 2) and (aktion = 1) then getroffen := 0;
   if getroffen = 3 then aktion := 16;
   if getroffen = 4 then aktion := 16;
   if (aktion in [15,16]) and (energie <= getroffen+treffermin) then aktion := 17;
   if (h1 <> getroffen) and sbready then wiedergabe(fx_vorbei);
   if beruehrt and ((yendrot = 90) xor (ch = ' ')) then
   begin
    gelenke[12].x := gelenke[12].x-5;
    gelenke[12].tox := gelenke[12].tox-5;
   end;
   if beruehrt and ((yendrot = 270) xor (ch = ' ')) then
   begin
    gelenke[12].x := gelenke[12].x+5;
    gelenke[12].tox := gelenke[12].tox+5;
   end;
   if ch = 'K' then aktion := 15;
   if ch = 'L' then aktion := 16;
   if ch = 'Q' then aktion := 17;
   case aktion of
    0 : nichts;
    1 : deckung;
    2 : ducken;
    3 : amhintern;
    4 : punch;
    5 : kick;
    6 : drehkick;
    7 : fegen;
    8 : spirale;
    9 : kick360;
    10 : bauchkick;
    11 : beamen;
    12 : sprung;
    13 : schrittr;
    14 : schrittl;
    15 : treffer;
    16 : sturz;
    17 : tot;
   end;
   if aktion in [0..6,8,10,13..15] then
   begin
    gelenke[12].z := 0;
    gelenke[12].toz := 0;
    fallen(1);
   end;
 END;

 PROCEDURE _Fighter.Put2Cs(var cs : vekball);
  var z1 : integer;
  begin
   for z1 := 1 to 26 do
   with hcs[z1] do
   begin
    rcs[z1].x := round(x*gelenke[14].x+gelenke[12].x-hcs[fixballnr].x*gelenke[14].x)+xpos;
    rcs[z1].y := round(-y*gelenke[14].y-hoehe-gelenke[12].y+hcs[fixballnr].y*gelenke[14].y)+ypos;
    rcs[z1].z := round(z*gelenke[14].z+gelenke[12].z-hcs[fixballnr].z*gelenke[14].z)+zpos;
    rcs[z1].rad := rad;
    rcs[z1].col := col;
   end;
   with rcs[1] do
   begin
    inx1 := x;
    inx2 := x;
    iny1 := y;
    iny2 := y;
    inz1 := z;
    inz2 := z;
   end;
   for z1 := 1 to 26 do
    if (z1 <> 4) or (gelenke[13].x+gelenke[13].y+gelenke[13].z = 0) then
    with rcs[z1] do
    begin
     if x-rad < inx1 then inx1 := x-rad;
     if y-rad < iny1 then iny1 := y-rad;
     if z-rad < inz1 then inz1 := z-rad;
     if x+rad > inx2 then inx2 := x+rad;
     if y+rad > iny2 then iny2 := y+rad;
     if z+rad > inz2 then inz2 := z+rad;
   end;
   if gelenke[14].x+gelenke[14].y+gelenke[14].z <> 3 then
    begin
     inx1 := xpos+round(gelenke[12].x);
     iny1 := ypos+round(gelenke[12].y);
     inz1 := zpos+round(gelenke[12].z);
     inx2 := inx1;
     iny2 := iny1;
     inz2 := inz1;
   end;
   for z1 := 1 to 26 do
    with rcs[z1] do cs.add(x,y,z,rad,color[col]);
 end;

 PROCEDURE LoadFile;
  var f : file of _chmap;
      z1 : byte;
  begin
   assign(f,fname);
   reset(f);
   for z1 := 0 to 255 do
    read(f,fdata[z1]);
   close(f);
 end;

 PROCEDURE Load_Chars(n : string);
  begin
   fname := n;
   loadfile;
 end;

 BEGIN
END.