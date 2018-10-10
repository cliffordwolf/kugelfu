program intro;

 uses vektorball, kf_objects, mode_x, crt, kf_tools;

 const x1 : integer = 2000;
       x2 : integer = 4300;
       y1 : integer = 400;
       subx1 = 5;
       subx2 = 10;
       adda1 = 1;
       adda2 = 3;
       addy1 = 5;

 var cs : vekball;
     txt1,txt2 : _vbstring;

 begin
  init_modex;
  cs.init(0,0,319,199,160,100,256);
  txt1.init;
  txt2.init;
  txt1.text := 'MADE BY CLIFFORD';
  txt1.a2 := (txt1.a1+90) mod 360;
  txt1.color := 2;
  txt2.text := 'KUGELFU -- MADE BY CLIFFORD -- KUGELFU';
  txt2.a2 := (txt2.a1+200) mod 360;
  txt2.color := 4;
  setballcol(0,63,63,40,1);
  setballcol(1,63,31,0,1);
  setballcol(2,30,63,30,1);
  setballcol(3,30,20,40,1);
  setballcol(4,20,40,40,1);
  preplists;
  loadmask('data\kugel.map');
  load_chars('data\vektchar.dat');
  while keypressed do readkey;
  repeat
   switch;
   waitretrace;
   delvpage;
   txt1.put2cs(x1,-100,400,10,cs);
   txt2.put2cs(x2,100,400,10,cs);
   cs.draw;
   cs.del;
   txt1.a1 := (txt1.a1+adda1) mod 360;
   txt2.a1 := (txt2.a1+adda2) mod 360;
   txt1.a2 := (txt1.a1+200);
   txt2.a2 := (txt2.a1+200);
   x1 := x1-subx1;
   x2 := x2-subx2;
   if x1 < -2000 then x1 := x1+4000;
   if x2 < -4300 then x2 := x2+8600;
  until keypressed;
  while keypressed do readkey;
  txt1.text := 'KUGELFU';
  txt1.color := 3;
  repeat
   switch;
   waitretrace;
   delvpage;
   txt1.put2cs(0,0,y1,10,cs);
   cs.draw;
   cs.del;
   txt1.a1 := (txt1.a1+adda2) mod 360;
   txt1.a2 := (txt1.a1);
   y1 := y1+addy1;
  until keypressed or (y1 > 880);
  txt1.color := 1;
  repeat
   switch;
   waitretrace;
   delvpage;
   txt1.put2cs(0,0,y1,10,cs);
   cs.draw;
   cs.del;
   txt1.a1 := (txt1.a1+adda2) mod 360;
   txt1.a2 := (txt1.a1);
   y1 := y1-addy1;
  until keypressed or (y1 < 100);
  while keypressed do readkey;
  fade_out;
  textmode(3);
end.