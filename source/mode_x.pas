UNIT Mode_X;

INTERFACE

 {*************************************************************************

   *) Paletten werden immer Åber Zeiger Åbergeben (@-Operator).

   *) Man kann mit der Procedure Switch zwischen der Bildschirmseite 1
      und der Bildschirmseite 2 wechseln. Der Offset der UNSICHTBAREN
      Seite Befindet sich immer in VPage. Die Procedure Switch wartet
      NICHT auf den Vertikal Raytrace. Daher vorher immer Waitraytrace
      aufrufen oder anders den vertikalen Raytrace abwarten.

   *) Mit der Procedure CRTC_Unprotect sehr vorsichtig umgehen. Falsch
      programmierte Timer-Werte kînnen schlechte Monitore zerstîren!

   *) Die Procedure Putpixel funktioniert im Double Modus (virtuelle
      horiz. Auflîsung von 640) nicht. Auserdem sollte sie auch im normalen
      Modus mîglichst vermieden werden.

 *************************************************************************}

 Var
  Vscreen:Pointer;              {Zeiger auf Quellbereich fÅr p13_2_modex}
  vpage:Word;                   {Offset der aktuell unsichtbaren Seite}
  palette:Array[0..256*3-1] of Byte; {VGA - Palette}

 PROCEDURE Init_ModeX;         {ModeX einschalten}

 PROCEDURE PutPixel(x,y:word; col:byte); {Setzt einen Punkt in Farbe col}
 FUNCTION GetPixel(x,y:word) : byte; {Ermittelt die Farbe eines Punktes}

 PROCEDURE CopyScreen(Ziel,Quelle:Word);  {Quell-Seite nach Ziel-Seite kop.}
 PROCEDURE Copy_Block(Ziel,Quelle,Breite,Hoehe:Word);
                               {kopiert Block von Quell-Offset nach Ziel}
 PROCEDURE ClrX(pmask:byte);   {Mode X - Bildschirm lîschen}

 PROCEDURE SetStart(t:Word);   {Startadresse des sichtbaren Bilds setzen}
 PROCEDURE Switch;             {zwischen Seite 0 und 1 hin und herschalten}

 PROCEDURE WaitRetrace;        {wartet auf Vertikal-Retrace}
 PROCEDURE SetPal;             {kopiert Palette in VGA-DAC}
 PROCEDURE GetPal;             {liest Palette aus VGA-DAC aus}

 PROCEDURE Fade_Out;           {blendet Bild aus}
 PROCEDURE Fade_To(Zielpal:pointer; Schritt:Byte);
                               {blendet von Palette nach Zielpal}
 PROCEDURE Pal_Rot(Start,Ziel:Word);
                               {Rotiert Palettenteil um 1,
                                wenn Start>Ziel nach oben, sonst unten}


 {interne Prozeduren:}
 PROCEDURE Screen_Off;         {schaltet Bildschirm aus}
 PROCEDURE Screen_On;          {schaltet Bildschirm wieder ein}
 PROCEDURE CRTC_Unprotect;     {ermîglicht Zugriff auf Horizontal-Timing}
 PROCEDURE CRTC_Protect;       {verbietet Zugriff wieder}

 PROCEDURE Make_bw(WorkPal:pointer); {Palette auf schwarz/wei·}

Implementation

 type hp = array [0..256*3-1] of byte;
 var p : ^hp;

  Procedure Init_ModeX;external;

  Procedure CopyScreen;external;
  Procedure Copy_Block;external;
  Procedure ClrX;external;

  Procedure SetStart;external;
  Procedure Switch;external;

  Procedure WaitRetrace;external;
  Procedure SetPal;external;
  Procedure GetPal;external;

  Procedure Fade_Out;external;
  Procedure Fade_To;external;
  Procedure Pal_Rot;external;
  {$l mode_x}


PROCEDURE PutPixel(x,y:word; col:byte);assembler;
 asm
  mov ax,0a000h
  mov es,ax

  mov cx,x              {Write-Plan bestimmen}
  and cx,3
  mov ax,1
  shl ax,cl
  mov ah,al
  mov dx,03c4h
  mov al,2
  out dx,ax

  mov ax,80             {Offset = Y*80 + X div 4 + VPage}
  mul y
  mov di,ax
  mov ax,x
  shr ax,2
  add di,ax
  add di,Vpage
  mov al,col
  mov es:[di],al
end;

 FUNCTION GetPixel(x,y:word) : byte; assembler;
 asm
  mov ax,0a000h
  mov es,ax

  mov ax,x              {Read-Plan bestimmen}
  mov ah,al
  and ah,3
  mov al,4
  mov dx,03ceh
  out dx,ax

  mov al,5
  out dx,al
  inc dx
  in al,dx
  and al, $F7
  out dx,al

  mov ax,80             {Offset = Y*80 + X div 4 + VPage}
  mul y
  mov di,ax
  mov ax,x
  shr ax,2
  add di,ax
  add di,Vpage
  mov al,es:[di]
end;



Procedure Screen_Off;
Begin
  Port[$3c4]:=1;                {Register 1 des TS (TS Mode) selektieren}
  Port[$3c5]:=Port[$3c5] or 32; {Bit 5 (Screen Off) setzen}
End;
Procedure Screen_On;
Begin
  Port[$3c4]:=1;                {Register 1 des TS (TS Mode) selektieren}
  Port[$3c5]:=Port[$3c5] and not 32;  {Bit 5 (Screen Off lîschen}
End;
Procedure CRTC_UnProtect;
Begin
  Port[$3d4]:=$11;              {Register 11h des CRTC (Vertical Sync End)}
  Port[$3d5]:=Port[$3d5] and not $80  {Bit 7 (Protection Bit) lîschen}
End;
Procedure CRTC_Protect;
Begin
  Port[$3d4]:=$11;              {Register 11h des CRTC (Vertical Sync End)}
  Port[$3d5]:=Port[$3d5] or $80 {Bit 7 (Protection Bit) setzen}
End;
Procedure Make_bw;              {Palette nach schwarz/wei· reduzieren}
Var i,sum:Word;                 {Wertung: 30% rot, 59% grÅn, 11% blau}
Begin
  p := workpal;
  For i:=0 to 255 do Begin
    Sum:=Round(p^[i*3]*0.3 + p^[i*3+1]*0.59 + p^[i*3+2]*0.11);
    FillChar(p^[i*3],3,Sum); {Werte eintragen}
  End;
End;

Begin
End.
