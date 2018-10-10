UNIT SB_Snd;

INTERFACE

 USES Dos;

 TYPE _WavHeader = record
                 riff_code : array [0..3] of char;
                 size1 : longint;
                 riff_type : array [0..3] of char;

                 fmt_code : array [0..3] of char;
                 size2 : longint;
                 stereo : word; {1 = Mono, 2 = Stereo}
                 kanalzahl : word; {Anzahl der Kan„le}
                 samplerate : longint; {in Herz}
                 bytesec : longint; {Byte pro Sec.}
                 bytesample : word; {Bytes pro Sample}
                 bitsample : word; {Bits pro Sample}

                 data_code : array [0..3] of char;
                 data_size : longint;
                end;

      _Sample = record
                 dat : pointer;
                 size : word;
                 freq : longint;
                end;

 CONST dsp_irq        : byte = $5;         { Interrupt des SB, Wert wird}
                                          { durch die Init-Routine     }
                                          {  ge„ndert                  }
       dma_ch            : byte = 1;       { DMA Chanel, standartm„áig  }
                                          { = 1, auf SB 16 ASP auch an-}
                                          { dere Werte m”glich ...     }
       dsp_adr           : word = $220;    { Die Base-Adress des DSP.   }
                                          { Wert wird durch die Init-  }
                                          { Routine ge„ndert           }

       dma_page : array[0..3] of byte = ($87,$83,$81,$81);
       dma_adr  : array[0..3] of byte = (0,2,4,6);
       dma_wc   : array[0..3] of byte = (1,3,5,7);

       freq : longint = 11000;

       sbinst : boolean = false;

       maxstep : word = 4096;

 PROCEDURE LoadWav(fname : string; var sample : _sample);

 PROCEDURE Wiedergabe(sample : _sample);

 {PROCEDURE Aufnahme(sample : _sample);}

 PROCEDURE Init_sb(irq,dma : byte; addr : word);

 PROCEDURE Done_SB;

 VAR OldSbInt : pointer;
     sbready : boolean;
     aktofs,aktseg : word;
     aktgr : word;
     rec : boolean;

IMPLEMENTATION

 PROCEDURE LoadWav(fname : string; var sample : _sample);
  var f : file;
      header : _wavheader;
      size,hgr : word;
      h1 : _sample;
  begin
   assign(f,fname);
   reset(f,1);
   blockread(f,header,44);
   hgr := filesize(f)-filepos(f);
   if hgr < 65530 then size := hgr else size := 65530;
   h1.freq := header.samplerate;
   h1.size := size;
   getmem(h1.dat,size);
   blockread(f,h1.dat^,size);
   close(f);
   sample := h1;
 end;

 PROCEDURE wr_dsp(v : byte);
 {
  Wartet, bis der DSP zum Schreiben bereit ist, und schreibt dann das
  in "v" bergebene Byte in den DSP
 }
 begin;
   while port[dsp_adr+$c] >= 128 do ;
   port[dsp_adr+$c] := v;
 end;

 PROCEDURE Play_Sb(Segm,Offs,dgr : word);
 {
  Diese Procedure spielt den ber Segm:Offs adressierten Block mit der
  Gr”áe dsize ab. Es ist darauf zu achten, das der DMA-Controller NICHT
  Seitenbergreifend arbeiten kann ...
 }
 var li : word;
 begin;
   sbready := false;
   port[$0A] := dma_ch+4;                { DMA-Kanal sperren          }
   Port[$0c] := 0;                        { Adresse des Puffers        }
   Port[$0B] := $48+dma_ch;              { fr Soundausgabe           }
   Port[dma_adr[dma_ch]] := Lo(offs);    { an DMA-Controller          }
   Port[dma_adr[dma_ch]] := Hi(offs);
   Port[dma_wc[dma_ch]] := Lo(dgr-1);  { Gr”áe des Blockes (block-  }
   Port[dma_wc[dma_ch]] := Hi(dgr-1);  { groesse) an DMA-Controller }
   Port[dma_page[dma_ch]] := Segm;
   wr_dsp($14);
   wr_dsp(Lo(dgr-1));             { Gr”áe des Blockes an       }
   wr_dsp(Hi(dgr-1));             { den DSP                    }
   Port[$0A] := dma_ch;            { DMA-Kanal freigeben        }
 end;

 PROCEDURE Record_Sb(Segm,Offs,dgr : word);
 {
  Diese Procedure nimmt den ber Segm:Offs adressierten Block mit der
  Gr”áe dsize auf. Es ist darauf zu achten, das der DMA-Controller NICHT
  Seitenbergreifend arbeiten kann ...
 }
 var li : word;
 begin;
   sbready := false;
   port[$0A] := dma_ch+4;                { DMA-Kanal sperren     }
   Port[$0c] := 0;                        { Adresse des Puffers   }
   Port[$0B] := $44+dma_ch;              { fr Soundausgabe      }
   Port[dma_adr[dma_ch]] := Lo(offs);    { an DMA-Controller     }
   Port[dma_adr[dma_ch]] := Hi(offs);
   Port[dma_wc[dma_ch]] := Lo(dgr-1);  { Gr”áe des Blockes (block-  }
   Port[dma_wc[dma_ch]] := Hi(dgr-1);  { groesse) an DMA-Controller }
   Port[dma_page[dma_ch]] := Segm;
   wr_dsp($24);
   wr_dsp(Lo(dgr-1));               { Gr”áe des Blockes an       }
   wr_dsp(Hi(dgr-1));               { den DSP                    }
   Port[$0A] := dma_ch;              { DMA-Kanal freigeben        }
 end;

 PROCEDURE SB_Step;
  var hgr : word;
      physpos : longint;
  begin
   if aktgr > 0 then
   begin
    hgr := $FFFF-aktofs;
    if hgr > aktgr then hgr := aktgr;
    if hgr > maxstep then hgr := maxstep;
    if hgr > $FFFF-aktofs then hgr := $FFFF-aktofs;
    if rec then record_sb(aktseg,aktofs,hgr)
     else play_sb(aktseg,aktofs,hgr);
    aktgr := aktgr-hgr;
    if $FFFF-aktofs = hgr then
    begin
     inc(aktseg);
     aktofs := 0;
    end else aktofs := aktofs+hgr;
    sbready := false;
   end;
 end;

 PROCEDURE NewSBInt; interrupt;
  var h : byte;
  begin
   h := port[dsp_adr+$E];
   sbready := true;
   sb_step;
   port[$20] := $20;
 end;

 FUNCTION Reset_sb : boolean;
 const ready = $AA;
 var ct, stat : byte;
 begin
   port[dsp_adr+$6] := 1;
   for ct := 1 to 100 do;
   port[dsp_adr+$6] := 0;
   stat := 0;
   ct := 0;
   while (stat <> ready) and (ct < 100) do
   begin
     stat := port[dsp_adr+$E];
     stat := port[dsp_adr+$A];
     inc(ct);
   end;
   Reset_sb := (stat = ready);
 end;

 PROCEDURE Init_sb(irq,dma : byte; addr : word);
  var irqmsk : byte;
  begin
   dsp_irq := irq;
   dma_ch := dma;
   dsp_adr := addr;
   if not reset_sb then
   begin
    writeln;
    writeln('Soundblaster fehlerhaft oder nicht vorhanden !');
    halt;
   end;
   wr_dsp($D1);
   wr_dsp($40);
   wr_dsp(256-(1000000 div freq));
   getintvec($8+dsp_irq,oldsbint);          { Alten Interrupt sichern,   }
   setintvec($8+dsp_irq,@newsbint);   { auf eigene Routine setzen  }
   irqmsk := 1 shl dsp_irq;               { Interrupt einmaskieren     }
   port[$21] := port[$21] and not irqmsk;
   sbready := true;
   sbinst := true;
 end;

 PROCEDURE Done_SB;
  begin
   if not sbinst then exit;
   sbready := false;
   setintvec($8+dsp_irq,oldsbint);
   sbinst := false;
 end;

 PROCEDURE Wiedergabe(sample : _sample);
  var physpos : longint;
      reg : registers;
      pt : pointer;
      gr : word;
  begin
   if not sbinst then exit;
   pt := sample.dat;
   gr := sample.size;
   physpos := seg(pt^);
   physpos := physpos shl 4;
   physpos := physpos + ofs(pt^);
   aktseg := physpos div $FFFF;
   aktofs := physpos mod $FFFF;
   aktgr := gr;
   rec := false;
   if sbready then sb_step;
 end;

 PROCEDURE Aufnahme(sample : _sample);
  var physpos : longint;
      reg : registers;
      pt : pointer;
      gr : word;
  begin
   if not sbinst then exit;
   pt := sample.dat;
   gr := sample.size;
   physpos := seg(pt^);
   physpos := physpos shl 4;
   physpos := physpos + ofs(pt^);
   aktseg := physpos div $FFFF;
   aktofs := physpos mod $FFFF;
   aktgr := gr;
   rec := true;
   if sbready then sb_step;
 end;


 BEGIN
  aktgr := 0;
  sbready := false;
END.