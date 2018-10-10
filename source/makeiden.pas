PROGRAM MakeIdent;

 USES _Ident,Crt;

 VAR ch : char;


 begin
  writeln;
  write('Username: '); readln(identblock.username); writeln;
  write(' Usernr.: '); readln(identblock.usernumber); writeln;
  writeln('Alle Angaben richtig (J/N)?');
  repeat ch := upcase(readkey) until ch in ['J','N'];
  if ch = 'J' then
  begin
   ident_readdat('kugelfu.exe');
   ident_save('ident.dat');
   ident_lade('ident.dat');
   if not ident_teste('kugelfu.exe') then write('** ERROR **');
  end else writeln('*** Programmabbruch ***');
end.