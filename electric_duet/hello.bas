   2  HOME 
   5  PRINT 
  10  PRINT "ELECTRIC DUET DEMOS"
  20  PRINT 
  30  PRINT "1. STILL ALIVE"
  35  PRINT "2. FF7 FIGHTING"
  40  PRINT "3. FF7 HIGHWIND"
  45  PRINT "4. KERBAL THEME"
 100  PRINT  CHR$ (4)"BLOAD ED"
 120  PRINT "-----> ";: INPUT A
 130  IF A < 0 OR A > 4 THEN  GOTO 120
 140  ON A GOTO 200,210,220,230
 200  PRINT  CHR$ (4)"BLOAD SA.ED,A$2000"
 205  GOTO 1000
 210  PRINT  CHR$ (4)"BLOAD FIGHTING.ED,A$2000"
 215  GOTO 1000
 220  PRINT  CHR$ (4)"BLOAD HIGHWIND.ED,A$2000"
 225  GOTO 1000
 230  PRINT  CHR$ (4)"BLOAD KERBAL.ED,A$2000"
 235  GOTO 1000
1000  POKE 30,0: POKE 31,32
1010 CALL 256*12
1020 GOTO 2
