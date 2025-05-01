' *********************************************
' *********************************************
' **                                         **
' ** HL.GFA: (sehr) elementare Harmonielehre **
' **         (Aussetzen von einfachen Gene-  **
' **          ralbässen und Funktionsfolgen  **
' **          in Dur mit grafischer Ausgabe) **
' **                                         **
' ** Programmiert in GFA-BASIC auf dem Com-  **
' ** modore Amiga. Geschrieben irgendwann    **
' ** zwischen Februar 1989 und März 1990 von **
' ** Christoph Hust. -- Ich war jung und     **
' ** hatte keine Ahnung. :)                  **
' **                                         **
' *********************************************
' *********************************************
'
' >>> Variablen initialisieren <<<
'
DIM stufe$(7,4),x$(10),vorzeichen$(2,6,2),akkord$(4),tonleiter$(12,2),oktave(4)
DIM lak$(4),moeglichkeit$(4,4),differenz(4,4),okta(4,4),bewertung(4),weg(4)
DIM leiter$(8)
GOSUB variablen
'
' >>> Modus etc. abfragen <<<
'
ALERT 1,"Programm-Modus?",1,"  GB  |  Akkorde ",modus
INPUT "Tonart: ",tonart$
GOSUB tonnameneinlesen
INPUT "Anzahl der Akkorde";zahl
DIM akkorde$(zahl),tonlaengen(zahl),kadenz$(zahl,4,4),baß$(zahl)
ALERT 1,"Ausgabe als Noten|oder als Text?",2," Text | Noten",zeichnen
'
' >>> Eingabeprozedur <<<
'
FOR i=1 TO zahl
  IF modus=gbaß THEN
    PRINT "Baßton Nr.";i;
    INPUT baß$(i)
    INPUT "Bezifferung";akkorde$(i)
    IF akkorde$(i)="/" THEN
      akkorde$(i)=akkorde$(i-1)
    ENDIF
    IF zeichnen=2 THEN
      ALERT 1,"Tonlänge?|1/1=Ganze, 1/2=Halbe, 1/4=Viertel",2," 1/1 | 1/2 | 1/4 ",tl
      SELECT tl
      CASE 1
        tonlaengen(i)=1
      CASE 2
        tonlaengen(i)=2
      CASE 3
        tonlaengen(i)=4
      ENDSELECT
    ENDIF
  ELSE
    PRINT "Akkord Nr.";i;
    INPUT akkorde$(i)
    akkorde$(i)=UPPER$(akkorde$(i))
    IF zeichnen=2 THEN
      ALERT 1,"Tonlänge?|1/1=Ganze, 1/2=Halbe, 1/4=Viertel",2," 1/1 | 1/2 | 1/4 ",tl
      SELECT tl
      CASE 1
        tonlaengen(i)=1
      CASE 2
        tonlaengen(i)=2
      CASE 3
        tonlaengen(i)=4
      ENDSELECT
    ENDIF
  ENDIF
  IF @gueltigerakkord(akkorde$(i))=0 THEN
    IF modus<>gbaß THEN
      ALERT 1,akkorde$(i)+": unbekannter Akkord.",1," NOCHMAL ",dummy
      DEC i
    ENDIF
  ENDIF
NEXT i
ALERT 1,"Lage des ersten Akkords?|3=Terzlage,|5=Quintlage,|8=Oktavlage",3," 3 | 5 | 8 ",l
SELECT l
CASE 1
  anfangslage=3
CASE 2
  anfangslage=5
CASE 3
  anfangslage=8
ENDSELECT
ALERT 1,"Weite oder|enge Lage?",1," eng | weit ",lagewe
'
' >>> Berechnung durchführen <<<
'
CLS
PRINT AT(4,4);"Einen Moment, ich rechne."
FOR nummer=1 TO zahl
  PRINT AT(5,5);"Ich bin momentan bei Akkord Nr. ";nummer;". Noch ";zahl-nummer;" Akkorde zu berechnen.   "
  PRINT AT(5,6);TIME$,DATE$
  IF modus=gbaß THEN
    GOSUB generalbaß(baß$(nummer),akkorde$(nummer))
  ELSE
    GOSUB akkord(akkorde$(nummer))
  ENDIF
  IF nochmal=1 THEN
    DEC nummer
  ELSE
    FOR stimme=baß TO sopran
      kadenz$(nummer,stimme,1)=akkord$(stimme)
      kadenz$(nummer,stimme,2)=STR$(oktave(stimme))
    NEXT stimme
    FOR i=baß TO sopran
      lak$(i)=akkord$(i)
    NEXT i
  ENDIF
NEXT nummer
'
' >>> Ausgabe <<<
'
CLS
IF zeichnen=2 THEN
  PUT 3,10,gschl$
  PUT 3,45,fschl$
  gt$="e"
  GOSUB stammton(gt$)
  gt$=stton$
  xposition=20
  GOSUB vorzeicheneintragen
  xposition=xposition+10
  PUT xposition,22,vier$
  PUT xposition,32,vier$
  PUT xposition,52,vier$
  PUT xposition,62,vier$
  xposition=xposition+30
  GOSUB stammton("c")
  c$=stton$
ENDIF
FOR nummer=1 TO zahl
  IF zeichnen=2 THEN
    PRINT AT(xposition/8+1,11+seite/10+(3*seite/100));akkorde$(nummer);
    FOR stimme=baß TO sopran
      GOSUB note(tonlaengen(nummer),kadenz$(nummer,stimme,1),VAL(kadenz$(nummer,stimme,2)))
    NEXT stimme
    tkt=tkt+1/tonlaengen(nummer)
    IF tkt>=1 THEN
      tkt=0
      GOSUB taktstrich
    ENDIF
    xposition=xposition+30
    IF xposition>=600 THEN
      IF seite=0 THEN
        seite=110
        xposition=0
        PUT 3,120,gschl$
        PUT 3,155,fschl$
        xposition=20
        GOSUB vorzeicheneintragen
        xposition=xposition+20
      ELSE
        GOSUB notenpapier
        ALERT 1,"Seite ist voll.|Ausdrucken?",2," Ja | Nein",druck
        IF druck=1 THEN
          HARDCOPY
        ENDIF
        CLS
        seite=0
        xposition=20
        PUT 3,10,gschl$
        PUT 3,45,fschl$
        GOSUB vorzeicheneintragen
        xposition=xposition+10
        PUT xposition,22,vier$
        PUT xposition,32,vier$
        PUT xposition,52,vier$
        PUT xposition,62,vier$
        xposition=xposition+30
      ENDIF
    ENDIF
  ELSE
    PRINT "Nr. ";nummer;": ";akkorde$(nummer);
    FOR stimme=sopran DOWNTO baß
      PRINT TAB(10*stimme);
      GOSUB ausgabe(kadenz$(nummer,stimme,1),VAL(kadenz$(nummer,stimme,2)))
    NEXT stimme
    PRINT
    PRINT STRING$(70,"-")
    IF nummer MOD 5=0 THEN
      REPEAT
      UNTIL INKEY$<>""
      CLS
    ENDIF
  ENDIF
NEXT nummer
IF zeichnen=2 THEN
  xposition=xposition-55
  GOSUB taktstrich
  xposition=xposition-28
  GOSUB taktstrich
  GOSUB notenpapier
  ALERT 1,"Ausdrucken?",2," Ja | Nein ",druck
  IF druck=1 THEN
    HARDCOPY
  ENDIF
ENDIF
END
'
' *******************
' ** Unterroutinen **
' *******************
'
' ----------
' - AKKORD -
' ----------
'
' baut mittels BILDEAKKORD die Akkorde in allen Lagen auf
' und speichert sie im Array "moeglichkeit$()"
'
PROCEDURE akkord(akkordname$)
  IF nummer=1 THEN                                    ! Erster Akkord
    GOSUB bildeakkord(akkordname$,anfangslage)
    GOSUB bestimmebaßton
    FOR i=1 TO 3
      FOR ton=baß TO sopran
        moeglichkeit$(i,ton)=akkord$(ton)
      NEXT ton
    NEXT i
    IF lagewe=1 THEN
      FOR i=tenor TO sopran
        ii=0
        DO
          INC ii
          EXIT IF tonleiter$(ii,1)=moeglichkeit$(1,i) OR tonleiter$(ii,2)=moeglichkeit$(1,i)
        LOOP
        SELECT i
        CASE 2
          IF ii>1 THEN
            DEC oktave(tenor)
          ENDIF
        CASE 3
          IF ii>3 THEN
            DEC oktave(alt)
          ENDIF
        CASE 4
          IF ii>10 THEN
            DEC oktave(sopran)
          ENDIF
        ENDSELECT
      NEXT i
    ELSE
      p=0
      DO
        INC p
        EXIT IF tonleiter$(p,1)=moeglichkeit$(1,baß) OR tonleiter$(p,2)=moeglichkeit$(1,baß)
      LOOP
      DO
        INC p
        IF p=13 THEN
          INC flg
          p=1
        ENDIF
        EXIT IF tonleiter$(p,1)=moeglichkeit$(1,tenor) OR tonleiter$(p,2)=moeglichkeit$(2,tenor)
      LOOP
      oktave(tenor)=oktave(baß)+flg
      flg=0
      DO
        INC p
        IF p=13 THEN
          INC flg
          p=1
        ENDIF
        EXIT IF tonleiter$(p,1)=moeglichkeit$(1,alt) OR tonleiter$(p,2)=moeglichkeit$(1,alt)
      LOOP
      oktave(alt)=oktave(tenor)+flg
      flg=0
      DO
        INC p
        IF p=13 THEN
          INC flg
          p=1
        ENDIF
        EXIT IF tonleiter$(p,1)=moeglichkeit$(1,sopran) OR tonleiter$(p,2)=moeglichkeit$(1,sopran)
      LOOP
      oktave(sopran)=oktave(alt)+flg
    ENDIF
    IF oktave(sopran)<3 THEN
      IF lagewe=2 THEN
        FOR stimme=baß TO sopran
          INC oktave(stimme)
        NEXT stimme
      ENDIF
    ENDIF
  ELSE
    GOSUB bildeakkord(akkordname$,3)    ! Akkord in Terzlage aufbauen
    FOR ton=baß TO sopran
      moeglichkeit$(1,ton)=akkord$(ton)
    NEXT ton
    GOSUB bildeakkord(akkordname$,5)                   ! in Quintlage
    FOR ton=baß TO sopran
      moeglichkeit$(2,ton)=akkord$(ton)
    NEXT ton
    GOSUB bildeakkord(akkordname$,8)               ! und in Oktavlage
    FOR ton=baß TO sopran
      moeglichkeit$(3,ton)=akkord$(ton)
    NEXT ton
    GOSUB bestimmebaßton
  ENDIF
  FOR n=1 TO 3
    FOR ton=tenor TO sopran
      okt=oktave(ton)
      GOSUB ermittledifferenz(akkord$(baß),moeglichkeit$(n,ton))
      IF nummer=1 THEN
        differenz(n,ton)=abstandaufwaerts
      ELSE
        GOSUB ermittledifferenz(lak$(ton),moeglichkeit$(n,ton))
        IF abstandaufwaerts>abstandabwaerts THEN
          differenz=-abstandabwaerts
        ELSE
          differenz=abstandaufwaerts
        ENDIF
        IF moeglichkeit$(n,ton)="ces" THEN
          IF differenz>0 THEN
            INC okt
          ENDIF
        ELSE
          IF lak$(ton)="ces" AND differenz<0 THEN
            DEC okt
          ENDIF
          IF position+differenz<=0 THEN
            DEC okt
          ELSE
            IF position+differen>12 THEN
              IF lak$(ton)<>"ces" THEN
                INC okt
              ENDIF
            ENDIF
          ENDIF
        ENDIF
      ENDIF
      okta(n,ton)=okt
      differenz(n,ton)=differenz
    NEXT ton
  NEXT n
  GOSUB akkordebewerten
  FOR i=2 TO 4
    akkord$(i)=moeglichkeit$(bestemoeglichkeit,i)
    oktave(i)=okta(bestemoeglichkeit,i)
  NEXT i
  IF oktave(tenor)<=oktave(baß) THEN
    p=0
    DO
      INC p
      EXIT IF tonleiter$(p,1)=akkord$(baß) OR tonleiter$(p,2)=akkord$(baß)
    LOOP
    DO
      INC p
      IF p=13 THEN
        flg=1
      ELSE
        flg=0
      ENDIF
      EXIT IF flg=1
      EXIT IF tonleiter$(p,1)=akkord$(tenor) OR tonleiter$(p,2)=akkord$(tenor)
    LOOP
    IF flg=1 THEN
      DEC oktave(baß)
    ENDIF
  ENDIF
  IF nummer=1 THEN
    IF oktave(3)>oktave(4) THEN
      INC oktave(sopran)
    ENDIF
    IF oktave(sopran)=oktave(alt) THEN
      p=0
      DO
        INC p
        EXIT IF tonleiter$(p,1)=akkord$(3) OR tonleiter$(p,2)=akkord$(3)
      LOOP
      DO
        INC p
        IF p=13 THEN
          flg=1
        ELSE
          flg=0
        ENDIF
        EXIT IF flg=1
        EXIT IF tonleiter$(p,1)=akkord$(4) OR tonleiter$(p,2)=akkord$(4)
      LOOP
      IF flg=0 THEN
        INC oktave(sopran)
      ENDIF
    ENDIF
    IF oktave(alt)-oktave(sopran)<2 THEN
      p=0
      DO
        INC p
        EXIT IF tonleiter$(p,1)=akkord$(3) OR tonleiter$(p,2)=akkord$(3)
      LOOP
      DO
        INC p
        IF p=13 THEN
          flg=1
        ELSE
          flg=0
        ENDIF
        EXIT IF flg=1
        EXIT IF tonleiter$(p,1)=akkord$(4) OR tonleiter$(p,2)=akkord$(4)
      LOOP
      IF flg=0 THEN
        DEC oktave(sopran)
      ENDIF
    ENDIF
  ENDIF
RETURN
'
' -------------------
' - AKKORDEBEWERTEN -
' -------------------
'
' bewertet die Akkorde nach definierten Satzregeln, könnte modular
' erweitert werden; speichert das Ergebnis in "bestemoeglichkeit" 
' und triggert ggf. eine neue Berechnung in weiter statt enger Lage 
' (oder vice versa)
'
PROCEDURE akkordebewerten
  ARRAYFILL bewertung(),0                  ! letzte Bewertung löschen
  ARRAYFILL weg(),0
  adressek=1
  adresseg=1
  FOR xx=1 TO 3
    FOR ton=tenor TO sopran               ! Kriterium I: gleiche Töne
      SELECT ton
      CASE 2
        IF okta(n,ton)=1 THEN
          GOSUB ermittledifferenz("c",moeglichkeit$(xx,ton))
          IF differenz<4 THEN
            bewertung(xx)=bewertung(xx)-0.5
          ENDIF
        ELSE
          IF okta(n,ton)<1 THEN
            DEC bewertung(xx)
          ELSE
            IF okta(n,ton)=2 THEN
              GOSUB ermittledifferenz("c",moeglichkeit$(xx,ton))
              IF differenz>11 THEN
                bewertung(xx)=bewertung(xx)-0.5
              ENDIF
            ELSE
              IF okta(n,ton)>2 THEN
                DEC bewertung(xx)
              ENDIF
            ENDIF
          ENDIF
        ENDIF
      CASE 3
        IF okta(n,ton)=1 THEN
          GOSUB ermittledifferenz("c",moeglichkeit$(xx,ton))
          IF differenz<11 THEN
            bewertung(xx)=bewertung(xx)-0.5
          ENDIF
        ELSE
          IF okta(n,ton)<1 THEN
            DEC bewertung(xx)
          ELSE
            IF okta(n,ton)=3 THEN
              GOSUB ermittledifferenz("c",moeglichkeit$(xx,ton))
              IF differenz>4 THEN
                bewertung(xx)=bewertung(xx)-0.5
              ENDIF
            ELSE
              IF okta(n,ton)>3 THEN
                DEC bewertung(xx)
              ENDIF
            ENDIF
          ENDIF
        ENDIF
      CASE 4
        IF okta(n,ton)=2 THEN
          GOSUB ermittledifferenz("c",moeglichkeit$(xx,ton))
          IF differenz<6 THEN
            bewertung(xx)=bewertung(xx)-0.5
          ENDIF
        ELSE
          IF okta(n,ton)<2 THEN
            DEC bewertung(xx)
          ELSE
            IF okta(n,ton)=3 THEN
              GOSUB ermittledifferenz("c",moeglichkeit$(xx,ton))
              IF differenz>11 THEN
                bewertung(xx)=bewertung(xx)-0.5
              ENDIF
            ELSE
              IF okta(n,ton)>3 THEN
                DEC bewertung(xx)
              ENDIF
            ENDIF
          ENDIF
        ENDIF
      ENDSELECT
      IF lak$(ton)=moeglichkeit$(xx,ton) THEN
        bewertung(xx)=bewertung(xx)+2
      ENDIF
    NEXT ton
    IF SGN(baßdifferenz)=((-1)*SGN(differenz(xx,sopran))) THEN             ! II: Gegenbewgg.
      INC bewertung(xx)
    ENDIF
    weg(xx)=ABS(differenz(xx,4))
  NEXT xx
  FOR xx=1 TO 3                        ! Kriterium III: kürzester Weg
    IF weg(xx)<=weg(adressek) THEN
      adressek=xx
    ELSE
      IF weg(xx)>=weg(adresseg) THEN
        adresseg=xx
      ENDIF
    ENDIF
  NEXT xx
  INC bewertung(adressek)
  DEC bewertung(adresseg)
  IF akkorde$(nummer)<>akkorde$(nummer-1) OR modus=gbaß THEN
    FOR i=1 TO 3
      FOR ton=baß TO sopran
        FOR ton2=baß TO sopran
          IF ton<>ton2 THEN
            IF nummer<>1 THEN
              GOSUB ermittlequint(moeglichkeit$(i,ton))
              IF moeglichkeit$(i,ton2)=quint$ OR moeglichkeit$(i,ton)=quintb$ OR moeglichkeit$(i,ton)=quintk$ THEN
                GOSUB ermittlequint(lak$(ton))
                IF lak$(ton2)=quint$ OR lak$(ton)=quintb$ OR lak$(ton)=quintk$ THEN
                  bewertung(i)=bewertung(i)-50  ! Krit. IV: Quintpar.
                ENDIF
              ENDIF
            ENDIF
            IF UPPER$(moeglichkeit$(i,ton))=UPPER$(moeglichkeit$(i,ton2)) THEN
              IF lak$(ton)=lak$(ton2) THEN
                IF differenz(i,ton)<>0 THEN
                  bewertung(i)=bewertung(i)-100  ! Krit. V: Oktavpar.
                ENDIF
              ENDIF
            ENDIF
          ENDIF
        NEXT ton2
      NEXT ton
    NEXT i
  ENDIF
  bestemoeglichkeit=1                        ! die Auswertung beginnt
  FOR xx=1 TO 3
    IF bewertung(xx)>=bewertung(bestemoeglichkeit) THEN
      bestemoeglichkeit=xx
    ENDIF
  NEXT xx
  IF bewertung(bestemoeglichkeit)<-50 THEN
    IF lagewe=1 THEN
      lagewe=2
    ELSE
      lagewe=1
    ENDIF
    nochmal=1                       ! keine gute Möglichkeit gefunden
  ELSE
    nochmal=0                                     ! We have a winner!
  ENDIF
RETURN
'
' ---------------------
' -- AKKORDEEINLESEN --
' ---------------------
'
PROCEDURE akkordeinlesen(stufe)
  IF stufe=7 THEN
    stufe=5
    d7=1
  ELSE
    d7=0
  ENDIF
  DEC stufe
  RESTORE toene
  FOR i2=1 TO ueber                   ! bis zum ersten Ton der Tonika
    READ dummy$
  NEXT i2
  x2=ueber
  FOR i2=1 TO stufe                       ! bis zur gewünschten Stufe
    READ dummy$
    INC x2
    IF x2=7 THEN
      x2=0
      RESTORE toene
    ENDIF
  NEXT i2
  FOR i2=1 TO 3                                     ! Akkord einlesen
    READ x$(i2)
    INC x2
    IF x2=7 THEN
      x2=0
      RESTORE toene
    ENDIF
    READ dummy$                       ! Akkorde sind Terzschichtungen
    INC x2
    IF x2=7 THEN
      x2=0
      RESTORE toene
    ENDIF
  NEXT i2
  IF d7=1 THEN
    READ x$(4)
  ELSE
    x$(4)=""
  ENDIF
  FOR i2=1 TO 4                                   ! Vorzeichen ändern
    FOR ii2=1 TO anzahl
      IF x$(i2)=vorzeichen$(art,ii2,1) THEN
        x$(i2)=vorzeichen$(art,ii2,2)
      ENDIF
    NEXT ii2
  NEXT i2
RETURN
'
' ------------------------
' - AKKORDZUSAMMENSETZEN -
' ------------------------
'
' wird von AKKORD angesprungen und setzt einen bestimmten Akkord in 
' einer bestimmten Lage zusammen im Array "akkord$()"
'
PROCEDURE akkordzusammensetzen
  akkord$(baß)=x$(1)
  IF lagewe=1 THEN                                        ! enge Lage
    IF stufe=7 THEN                                      ! Septakkord
      SELECT lage
      CASE 3                                               ! Terzlage
        akkord$(tenor)=x$(3)
        akkord$(alt)=x$(4)
        akkord$(sopran)=x$(2)
      CASE 5                                              ! Quintlage
        akkord$(tenor)=x$(4)
        akkord$(alt)=x$(2)
        akkord$(sopran)=x$(3)
      CASE 8                                              ! Oktavlage
        akkord$(tenor)=x$(2)
        akkord$(alt)=x$(3)
        akkord$(sopran)=x$(4)
      ENDSELECT
    ELSE
      SELECT lage
      CASE 8                                              ! Oktavlage
        akkord$(tenor)=x$(2)
        akkord$(alt)=x$(3)
        akkord$(sopran)=x$(1)
      CASE 5                                              ! Quintlage
        akkord$(tenor)=x$(1)
        akkord$(alt)=x$(2)
        akkord$(sopran)=x$(3)
      CASE 3                                               ! Terzlage
        akkord$(tenor)=x$(3)
        akkord$(alt)=x$(1)
        akkord$(sopran)=x$(2)
      ENDSELECT
    ENDIF
  ELSE                                                  ! weite Lage
    IF stufe=7 THEN                                 ! alles wie oben
      SELECT lage
      CASE 3
        akkord$(sopran)=x$(2)
        akkord$(alt)=x$(3)
        akkord$(tenor)=x$(4)
      CASE 5
        akkord$(sopran)=x$(3)
        akkord$(alt)=x$(4)
        akkord$(tenor)=x$(2)
      CASE 8
        akkord$(sopran)=x$(4)
        akkord$(alt)=x$(2)
        akkord$(tenor)=x$(3)
      ENDSELECT
    ELSE
      SELECT lage
      CASE 8
        akkord$(sopran)=x$(1)
        akkord$(alt)=x$(2)
        akkord$(tenor)=x$(3)
      CASE 5
        akkord$(sopran)=x$(3)
        akkord$(alt)=x$(1)
        akkord$(tenor)=x$(2)
      CASE 3
        akkord$(sopran)=x$(2)
        akkord$(alt)=x$(3)
        akkord$(tenor)=x$(1)
      ENDSELECT
    ENDIF
  ENDIF
RETURN
'
' -----------
' - AUSGABE -
' -----------
'
' Prozedur zur Textausgabe
'
PROCEDURE ausgabe(name$,hoehe)
  SELECT hoehe
  CASE 0
    PRINT UPPER$(name$),
  CASE 1
    PRINT name$,
  DEFAULT
    PRINT name$;
    FOR i=1 TO hoehe-1
      PRINT "'";
    NEXT i
    PRINT "",
  ENDSELECT
RETURN
'
' -------------------
' - BESTIMMEBASSTON -
' -------------------
'
' bestimmt den Basston
'
PROCEDURE bestimmebaßton
  IF nummer=1 THEN
    lak$(baß)=akkord$(baß)
    IF akkord$(baß)<>"ces" AND akkord$(baß)<>"c" AND akkord$(baß)<>"cis" AND akkord$(baß)<>"des" AND akkord$(baß)<>"d" AND akkord$(baß)<>"dis" AND akkord$(baß)<>"es" AND akkord$(baß)<>"e" AND akkord$(baß)<>"eis" THEN
      DEC oktave(baß)
    ENDIF
  ENDIF
  GOSUB ermittledifferenz(lak$(baß),akkord$(baß))
  IF abstandabwaerts<abstandaufwaerts THEN
    differenz=-abstandabwaerts
  ELSE
    differenz=abstandaufwaerts
  ENDIF
  REPEAT
    SELECT nochmal
    CASE 1
      differenz=abstandaufwaerts
    CASE 2
      differenz=-abstandabwaerts
    ENDSELECT
    okt=oktave(baß)
    GOSUB ermittleoktave
    oktave(baß)=okt
    nochmal=0
    IF oktave(baß)=0 AND (akkord$(baß)="des" OR akkord$(baß)="d" OR akkord$(baß)="dis" OR akkord$(baß)="ces" OR akkord$(baß)="c" OR akkord$(baß)="cis") THEN
      nochmal=1
    ELSE
      IF oktave(baß)<0 THEN
        nochmal=1
      ENDIF
    ENDIF
    IF oktave(baß)=2 AND NOT (akkord$(baß)="ces" OR akkord$(baß)="c" OR akkord$(baß)="cis" OR akkord$(baß)="des" OR akkord$(baß)="d" OR akkord$(baß)="dis" OR akkord$(baß)="es" OR akkord$(baß)="e" OR akkord$(baß)="eis") THEN
      nochmal=2
    ELSE
      IF oktave(baß)>2 THEN
        nochmal=2
      ENDIF
    ENDIF
  UNTIL nochmal=0
  baßdifferenz=differenz
RETURN
'
' ---------------
' - BILDEAKKORD -
' ---------------
'
' übersetzt zuerst Funktionen in Stufen und springt dann
' AKKORDZUSAMMENSETZEN an
'
PROCEDURE bildeakkord(funktion$,lage)
  SELECT funktion$               ! "Funktionen" sind hier nur schicke
  CASE "T"                             ! Synonyme für Stufen (leider)
    stufe=1
  CASE "SP"
    stufe=2                        ! (Und auch das lediglich in Dur.)
  CASE "DP"
    stufe=3
  CASE "S"
    stufe=4
  CASE "D"
    stufe=5
  CASE "TP"
    stufe=6
  CASE "D7"
    stufe=7
  ENDSELECT
  FOR i=1 TO 4
    x$(i)=stufe$(stufe,i)
  NEXT i
  GOSUB akkordzusammensetzen
RETURN
'
' ------------------
' - BILDEINTERVALL -
' ------------------
'
' bildet Intervalle für Generalbass und Stufen/Funktionen
'
PROCEDURE bildeintervall(grund$,intervall%)
  LOCAL position%,int%
  DEC intervall%
  IF INT(intervall%/7)=(intervall%/7) THEN
    intervall$=baßton$
  ELSE
    position%=0
    int%=0
    DO
      INC position%
      IF position%>12 THEN
        position%=1
      ENDIF
      EXIT IF tonleiter$(position%,1)=grund$ OR tonleiter$(position%,2)=grund$
    LOOP
    DO
      INC position%
      IF position%>12 THEN
        position%=1
      ENDIF
      IF LEN(tonleiter$(position%,1))=1 OR LEN(tonleiter$(position%,2))=1 THEN
        IF tonleiter$(position%,2)<>"b" THEN
          INC int%
        ENDIF
      ENDIF
      EXIT IF int%=intervall%
    LOOP
    IF LEN(tonleiter$(position%,1))=1 THEN
      intervall$=tonleiter$(position%,1)
    ELSE
      intervall$=tonleiter$(position%,2)
    ENDIF
  ENDIF
RETURN
'
' ---------------------
' - ERMITTLEDIFFERENZ -
' ---------------------
'
' bestimmt die Differenz zweier Töne, u. a. als Entscheidungsgrund-
' lage für die Bestimmung der Variante mit dem nächsten Weg
'
PROCEDURE ermittledifferenz(tona$,tonb$)
  position=0
  abstandaufwaerts=0
  abstandabwaerts=0
  RESTORE tonleiter
  DO
    INC position
    EXIT IF tonleiter$(position,1)=tona$ OR tonleiter$(position,2)=tona$
  LOOP
  IF tona$<>tonb$ THEN
    position2=position
    DO
      INC position2
      INC abstandaufwaerts
      IF position2=13 THEN
        position2=1
      ENDIF
      EXIT IF tonleiter$(position2,1)=tonb$ OR tonleiter$(position2,2)=tonb$
    LOOP
    position2=position
    DO
      DEC position2
      INC abstandabwaerts
      IF position2=0 THEN
        position2=12
      ENDIF
      EXIT IF tonleiter$(position2,1)=tonb$ OR tonleiter$(position2,2)=tonb$
    LOOP
  ENDIF
RETURN
'
' -------------------------
' - ERMITTLEDIFFERENZ_OKT -
' -------------------------
'
' bestimmt die Differenz von Oktavlagen
'
PROCEDURE ermittledifferenz_okt(tona$,tonb$,okt_a,okt_b)
  IF okt_a<0 THEN
    okt_a=0
  ENDIF
  IF okt_b<0 THEN
    okt_b=0
  ENDIF
  position=0
  differenz_o=0
  DO
    INC position
    EXIT IF leiter$(position)=tona$
  LOOP
  okt=okt_a
  IF NOT (tona$=tonb$ AND okt_a=okt_b) THEN
    position2=position
    DO
      DO
        INC position2
        IF position2=8 THEN
          INC okt
          position2=1
        ENDIF
        INC differenz_o
        EXIT IF leiter$(position2)=tonb$
      LOOP
      EXIT IF okt_b=okt
    LOOP
  ENDIF
RETURN
'
' ------------------
' - ERMITTLEOKTAVE -
' ------------------
'
' Oktavlage eines Tons bestimmen.
' Die Prozedur arbeitet in Fis-Dur fehlerhaft!
'
PROCEDURE ermittleoktave
  IF akkord$(baß)="ces" THEN
    IF differenz>0 THEN
      INC okt
    ENDIF
  ELSE
    IF lak$(baß)="ces" AND differenz<0 THEN
      DEC okt
    ENDIF
    IF position+differenz<=0 THEN
      DEC okt
    ELSE
      IF position+differenz>12 THEN
        IF lak$(baß)<>"ces" THEN
          INC okt
        ENDIF
      ENDIF
    ENDIF
  ENDIF
RETURN
'
' -----------------
' - ERMITTLEQUINT -
' -----------------
'
' Ermittelt die Quint über einem Ton. Entscheidungsgrundlage für die
' Abwertung von Stimmführungen mit Quintparallelen.
'
PROCEDURE ermittlequint(ton$)
  gpos=0
  DO
    INC gpos
    IF gpos>12 THEN
      gpos=1
    ENDIF
    EXIT IF ton$=tonleiter$(gpos,1) OR ton$=tonleiter$(gpos,2)
  LOOP
  IF ton$=tonleiter$(gpos,1) THEN
    art=1
  ELSE
    art=2
  ENDIF
  gpos=gpos+7
  IF gpos=>13 THEN
    gpos=gpos-12
  ENDIF
  IF ton$="eis" THEN
    quint$="his"
  ELSE
    quint$=tonleiter$(gpos,art)
  ENDIF
  IF quint$="h" THEN
    quintb$="b"
    quintk$="his"
  ELSE
    quintb$=quint$+"es"
    quintk$=quint$+"is"
  ENDIF
RETURN
'
' ---------------
' - GENERALBASS -
' ---------------
'
' Steuerung des Generalbass-Modus.
'
PROCEDURE generalbaß(baßton$,bezifferung$)
  LOCAL i%,baßton$,anz_ziff%4
  ERASE ziffern%()
  FOR i%=1 TO 10
    x$(i%)=""
  NEXT i%
  SELECT bezifferung$
  CASE ""
    bezifferung$="135"
  CASE "36"
    bezifferung$="136"
  CASE "6"
    bezifferung$="136"
  CASE "46"
    bezifferung$="146"
  CASE "4"
    bezifferung$="145"
  CASE "3"
    bezifferung$="135"
  CASE "5"
    bezifferung$="135"
  CASE "7"
    bezifferung$="1357"
  CASE "56"
    bezifferung$="1356"
  CASE "34"
    bezifferung$="1346"
  CASE "2"
    bezifferung$="1246"
  CASE "t.s."
    bezifferung$="0"
  ENDSELECT
  IF bezifferung$="0" THEN
    FOR i=1 TO 4
      akkorde$(i)=""
    NEXT i
  ELSE
    anz_ziff%=LEN(bezifferung$)
    DIM ziffern%(anz_ziff%)
    FOR i%=1 TO anz_ziff%
      ziffern%(i%)=VAL(MID$(bezifferung$,i%,1))
    NEXT i%
    QSORT ziffern%()
    GOSUB stammton_gbaß(baßton$)
    baßton$=stton$
    FOR i%=1 TO anz_ziff%
      GOSUB bildeintervall(baßton$,ziffern%(i%))
      GOSUB vorzeichen(intervall$)
      x$(i%)=v_ton$
    NEXT i%
    IF anz_ziff%=4 THEN
      stufe=7
    ELSE
      stufe=1
    ENDIF
    IF nummer=1 THEN
      lage=anfangslage
      GOSUB akkordzusammensetzen
      FOR ton=baß TO sopran
        moeglichkeit$(1,ton)=akkord$(ton)
        akkord$(ton)=akkord$(ton)                  ! sieht falsch aus
      NEXT ton
      IF lagewe=1 THEN
        FOR i=tenor TO sopran
          ii=0
          DO
            INC ii
            EXIT IF tonleiter$(ii,1)=moeglichkeit$(1,i) OR tonleiter$(ii,2)=moeglichkeit$(1,i)
          LOOP
          SELECT i
          CASE 2
            IF ii>11 THEN
              DEC oktave(tenor)
            ENDIF
          CASE 3
            IF ii>3 THEN
              DEC oktave(alt)
            ENDIF
          CASE 4
            IF ii>10 THEN
              DEC oktave(sopran)
            ENDIF
          ENDSELECT
        NEXT i
      ELSE
        p=0
        DO
          INC p
          EXIT IF tonleiter$(p,1)=moeglichkeit$(1,baß) OR tonleiter$(p,2)=moeglichkeit$(1,baß)
        LOOP
        DO
          INC p
          IF p=13 THEN
            INC flg
            p=1
          ENDIF
          EXIT IF tonleiter$(p,1)=moeglichkeit$(1,tenor) OR tonleiter$(p,2)=moeglichkeit$(1,tenor)
        LOOP
        oktave(tenor)=oktave(baß)+flg
        flg=0
        DO
          INC p
          IF p=13 THEN
            INC flg
            p=1
          ENDIF
          EXIT IF tonleiter$(p,1)=moeglichkeit$(1,alt) OR tonleiter$(p,2)=moeglichkeit$(1,alt)
        LOOP
        oktave(alt)=oktave(tenor)+flg
        flg=0
        DO
          INC p
          IF p=13 THEN
            INC flg
            p=1
          ENDIF
          EXIT IF tonleiter$(p,1)=moeglichkeit$(1,sopran) OR tonleiter$(p,2)=moeglichkeit$(1,sopran)
        LOOP
        oktave(sopran)=oktave(alt)+flg
      ENDIF
      IF oktave(sopran)<3 THEN
        IF lagewe=2 THEN
          FOR stimme=baß TO sopran
            INC oktave(stimme)
          NEXT stimme
        ENDIF
      ENDIF
    ELSE
      lage=3
      GOSUB akkordzusammensetzen
      FOR ton=tenor TO sopran
        moeglichkeit$(2,ton)=akkord$(ton)
      NEXT ton
      lage=5
      GOSUB akkordzusammensetzen
      FOR ton=tenor TO sopran
        moeglichkeit$(3,ton)=akkord$(ton)
      NEXT ton
      lage=8
      GOSUB akkordzusammensetzen
      FOR ton=tenor TO sopran
        moeglichkeit$(1,ton)=akkord$(ton)
      NEXT ton
      GOSUB bestimmebaßton
      FOR i%=1 TO 3
        moeglichkeit$(i%,1)=baßton$
      NEXT i%
      FOR n=1 TO 3
        FOR ton=tenor TO sopran
          okt=oktave(ton)
          GOSUB ermittledifferenz(akkord$(baß),moeglichkeit$(n,ton))
          IF nummer=1 THEN
            differenz(n,ton)=abstandaufwaerts
          ELSE
            GOSUB ermittledifferenz(lak$(ton),moeglichkeit$(n,ton))
            IF abstandaufwaerts>abstandabwaerts THEN
              differenz=-abstandabwaerts
            ELSE
              differenz=abstandaufwaerts
            ENDIF
            IF moeglichkeit$(n,ton)="ces" THEN
              IF differenz>0 THEN
                INC okt
              ENDIF
            ELSE
              IF lak$(ton)="ces" AND differenz<0 THEN
                DEC okt
              ENDIF
              IF position+differenz<=0 THEN
                DEC okt
              ELSE
                IF position+differenz>12 THEN
                  IF lak$(ton)<>"ces" THEN
                    INC okt
                  ENDIF
                ENDIF
              ENDIF
            ENDIF
          ENDIF
          okta(n,ton)=okt
          differenz(n,ton)=differenz
        NEXT ton
      NEXT n
      GOSUB akkordebewerten
      FOR i=2 TO 4
        akkord$(i)=moeglichkeit$(bestemoeglichkeit,i)
        oktave(i)=okta(bestemoeglichkeit,i)
      NEXT i
      IF oktave(tenor)<=oktave(baß) THEN
        p=0
        DO
          INC p
          EXIT IF tonleiter$(p,1)=akkord$(baß) OR tonleiter$(p,2)=akkord$(baß)
        LOOP
        DO
          INC p
          IF p=13 THEN
            flg=1
          ELSE
            flg=0
          ENDIF
          EXIT IF flg=1
          EXIT IF tonleiter$(p,1)=akkord$(tenor) OR tonleiter$(p,2)=akkord$(tenor)
        LOOP
        IF flg=1 THEN
          DEC oktave(baß)
        ENDIF
      ENDIF
      IF nummer=1 THEN
        IF oktave(3)>oktave(4) THEN
          INC oktave(sopran)
        ENDIF
        IF oktave(sopran)=oktave(alt) THEN
          p=0
          DO
            INC p
            EXIT IF tonleiter$(p,1)=akkord$(3) OR tonleiter$(p,2)=akkord$(3)
          LOOP
          DO
            INC p
            IF p=13 THEN
              flg=1
            ELSE
              flg=0
            ENDIF
            EXIT IF flg=1
            EXIT IF tonleiter$(p,1)=akkord$(4) OR tonleiter$(p,2)=akkord$(4)
          LOOP
          IF flg=0 THEN
            INC oktave(sopran)
          ENDIF
        ENDIF
        IF oktave(alt)-oktave(sopran)<2 THEN
          p=0
          DO
            INC p
            EXIT IF tonleiter$(p,1)=akkord$(3) OR tonleiter$(p,2)=akord$(3)
          LOOP
          DO
            INC p
            IF p=13 THEN
              flg=1
            ELSE
              flg=0
            ENDIF
            EXIT IF flg=1
            EXIT IF tonleiter$(p,1)=akkord$(4) OR tonleiter$(p,2)=akkord$(4)
          LOOP
          IF flg=0 THEN
            DEC oktave(sopran)
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  ENDIF
RETURN
'
' ------------
' - STAMMTON -
' ------------
'
' Stammton eines chromatisierten Tons bestimmen
'
PROCEDURE stammton(name$)
  IF name$="his" OR name$="b" THEN
    stton$="h"
  ELSE
    IF name$="fes" OR name$="fis" OR name$="f" THEN
      stton$="f"
    ELSE
      IF name$="ces" THEN
        stton$="c"
      ELSE
        IF name$="as" THEN
          stton$="a"
        ELSE
          RESTORE tonleiter
          DO
            INC pos
            IF pos=13 THEN
              pos=1
            ENDIF
            EXIT IF tonleiter$(pos,1)=name$ OR tonleiter$(pos,2)=name$
          LOOP
          IF INSTR(name$,"is") THEN
            DEC pos
          ELSE
            IF INSTR(name$,"es") THEN
              INC pos
            ENDIF
          ENDIF
          stton$=tonleiter$(pos,1)
        ENDIF
      ENDIF
    ENDIF
  ENDIF
  FOR ii2=1 TO anzahl
    IF stton$=vorzeichen$(art,ii2,1) THEN
      stton$=vorzeichen$(art,ii2,2)
    ENDIF
  NEXT ii2
RETURN
'
' -----------------
' - STAMMTON_BASS -
' -----------------
'
' gleiche Funktion für Generalbass
'
PROCEDURE stammton_gbaß(name$)
  IF name$="his" OR name$="b" THEN
    stton$="h"
  ELSE
    IF name$="fes" OR name$="fis" OR name$="f" THEN
      stton$="f"
    ELSE
      IF name$="ces" THEN
        stton$="c"
      ELSE
        IF name$="as" THEN
          stton$="a"
        ELSE
          RESTORE tonleiter
          DO
            INC pos
            IF pos=13 THEN
              pos=1
            ENDIF
            EXIT IF tonleiter$(pos,1)=name$ OR tonleiter$(pos,2)=name$
          LOOP
          IF INSTR(name$,"is") THEN
            DEC pos
          ELSE
            IF INSTR(name$,"es") THEN
              INC pos
            ENDIF
          ENDIF
          stton$=tonleiter$(pos,1)
        ENDIF
      ENDIF
    ENDIF
  ENDIF
RETURN
'
' --------
' - NOTE -
' --------
'
' Ausgabe einer Note
'
PROCEDURE note(laenge,nam$,oktave)
  start=75
  IF oktave=2 AND LEFT$(nam$)="c" THEN
    LINE xposition-8,45+seite,xposition+8,45+seite
  ENDIF
  GOSUB ermittledifferenz_okt(gt$,nam$,0,oktave)
  yposition=start-(2.5*differenz_o)+seite
  GOSUB zeichnenote(xposition,yposition,laenge)
  IF oktave>=3 THEN
    GOSUB ermittledifferenz_okt(c$,nam$,3,oktave)
    IF differenz_o>=5 THEN
      IF (differenz_o/2)<>INT(differenz_o/2) THEN
        hl=INT(differenz_o/2)
      ELSE
        hl=INT(differenz_o/2)-1
      ENDIF
      FOR i=1 TO hl
        LINE xposition-8,40-i*5+seite-15,xposition+8,40-i*5+seite-15
      NEXT i
    ENDIF
  ENDIF
RETURN
'
' ---------------
' - NOTENPAPIER -
' ---------------
'
' Notenlinien zeichnen
'
PROCEDURE notenpapier
  LOCAL y,i,ii,iii
  COLOR 1
  y=20
  FOR i=1 TO 2
    FOR ii=1 TO 2
      FOR iii=1 TO 5
        LINE 0,y,639,y
        y=y+5
      NEXT iii
      y=y+5
    NEXT ii
    y=y+5
  NEXT i
RETURN
'
' --------------
' - TAKTSTRICH -
' --------------
'
' Taktstrich zeichnen
'
PROCEDURE taktstrich
  xposition=xposition+30
  LINE xposition,70+seite,xposition,20+seite
  LINE xposition+1,70+seite,xposition+1,20+seite
RETURN
'
' -------------------
' - TONARTBESTIMMEN -
' -------------------
'
' 1. wie viele Töne incl. c werden bis zum Grundton der Tonart 
'    überlesen? -> "ueber"
' 2. was für Vorzeichen (Be oder Kreuz)? -> "art"
' 3. wie viele Vorzeichen? -> "anzahl"
'
PROCEDURE tonartbestimmen
  SELECT UPPER$(tonart$)
  CASE "GES"
    ueber=4
    art=2
    anzahl=6
  CASE "DES"
    ueber=1
    art=2
    anzahl=5
  CASE "AS"
    ueber=5
    art=2
    anzahl=4
  CASE "ES"
    ueber=2
    art=2
    anzahl=3
  CASE "B"
    ueber=6
    art=2
    anzahl=2
  CASE "F"
    ueber=3
    art=2
    anzahl=1
  CASE "C"
    ueber=0
    art=0
    anzahl=0
  CASE "G"
    ueber=4
    art=1
    anzahl=1
  CASE "D"
    ueber=1
    art=1
    anzahl=2
  CASE "A"
    ueber=5
    art=1
    anzahl=3
  CASE "E"
    ueber=2
    art=1
    anzahl=4
  CASE "H"
    ueber=6
    art=1
    anzahl=5
  CASE "FIS"
    ueber=3
    art=1
    anzahl=6
  DEFAULT
    ALERT 1,UPPER$(tonart$)+"-Dur: unbekannte Tonart",1,"Programmende",dummy
    EDIT
  ENDSELECT
RETURN
'
' ---------------------
' - TONLEITEREINLESEN -
' ---------------------
'
' Tonleiter aus dem Datenteil einlesen
'
PROCEDURE tonleitereinlesen
  RESTORE tonleiter
  FOR i=1 TO 12
    READ anzahl
    IF anzahl=1 THEN
      READ tonleiter$(i,1)
      tonleiter$(i,2)=tonleiter$(i,1)
    ELSE
      READ tonleiter$(i,1)
      READ tonleiter$(i,2)
    ENDIF
  NEXT i
RETURN
'
' --------------------
' - TONNAMENEINLESEN -
' --------------------
'
' Tonnamen aus dem Datenteil einlesen
'
PROCEDURE tonnameneinlesen
  GOSUB tonleitereinlesen
  GOSUB tonartbestimmen
  GOSUB vorzeicheneinlesen
  FOR i=1 TO 7
    GOSUB akkordeinlesen(i)
    FOR ii=1 TO 4
      stufe$(i,ii)=x$(ii)
    NEXT ii
  NEXT i
  leiter$(1)="c"
  leiter$(2)="d"
  leiter$(3)="e"
  leiter$(4)="f"
  leiter$(5)="g"
  leiter$(6)="a"
  leiter$(7)="h"
  FOR ii=1 TO 7
    FOR i=1 TO anzahl
      IF leiter$(ii)=vorzeichen$(art,i,1) THEN
        leiter$(ii)=vorzeichen$(art,i,2)
      ENDIF
    NEXT i
  NEXT ii
RETURN
'
' --------------
' - UEBERLESEN -
' --------------
'
' Daten ignorieren
'
PROCEDURE ueberlesen(i)
  FOR x%=1 TO i
    READ dummy$
  NEXT x%
RETURN
'
' -------------
' - VARIABLEN -
' -------------
'
' Variablen initialisieren
'
PROCEDURE variablen
  gbaß=1
  baß=1
  tenor=2
  alt=3
  sopran=4
  oktave(baß)=1
  oktave(tenor)=2
  oktave(alt)=3
  oktave(sopran)=3
  PRINT "#"
  GET 0,0,8,8,kreuz$
  CLS
  PRINT "b"
  GET 0,0,8,8,b$
  CLS
  PRINT "4"
  GET 0,0,8,8,vier$
  CLS
  GOSUB schluesselzeichnen
RETURN
'
' --------------
' - VORZEICHEN -
' --------------
'
PROCEDURE vorzeichen(ton$)
  LOCAL i%
  v_ton$=ton$
  FOR i%=1 TO anzahl
    IF ton$=vorzeichen$(art,i%,1) THEN
      v_ton$=vorzeichen$(art,i%,2)
    ENDIF
  NEXT i%
RETURN
'
' ----------------------
' - VORZEICHENEINLESEN -
' ----------------------
'
PROCEDURE vorzeicheneinlesen
  RESTORE vorzeichen
  FOR i=1 TO 2
    FOR ii=1 TO 6
      FOR iii=1 TO 2
        READ vorzeichen$(i,ii,iii)
      NEXT iii
    NEXT ii
  NEXT i
RETURN
'
' -----------------------
' - VORZEICHENEINTRAGEN -
' -----------------------
'
' Vorzeichnung bei graphischer Ausgabe
'
PROCEDURE vorzeicheneintragen               ! man kann's auch zu Tode
  SELECT art                                     ! "strukturieren"...
  CASE 1
    GOSUB vorzeicheneintragen_k
  CASE 2
    GOSUB vorzeicheneintragen_b
  ENDSELECT
RETURN
'
' -------------------------
' - VORZEICHENEINTRAGEN_B -
' -------------------------
'
PROCEDURE vorzeicheneintragen_b
  oktave=3
  xposition=35
  FOR i=1 TO anzahl
    SELECT i
    CASE 2
      INC oktave
    CASE 3
      DEC oktave
    CASE 4
      INC oktave
    CASE 5
      DEC oktave
    CASE 6
      INC oktave
    ENDSELECT
    GOSUB ermittledifferenz_okt(gt$,vorzeichen$(art,i,2),0,oktave)
    yposition=90-(2.5*differenz_o)-1+seite
    PUT xposition,yposition,b$
    xposition=xposition+10
  NEXT i
  oktave=1
  xposition=35
  FOR i=1 TO anzahl
    SELECT i
    CASE 2
      INC oktave
    CASE 3
      DEC oktave
    CASE 4
      INC oktave
    CASE 5
      DEC oktave
    CASE 6
      INC oktave
    ENDSELECT
    GOSUB ermittledifferenz_okt(gt$,vorzeichen$(art,i,2),0,oktave)
    yposition=90-(2.5*differenz_o)-1+seite
    PUT xposition,yposition,b$
    xposition=xposition+10
  NEXT i
RETURN
'
' -------------------------
' - VORZEICHENEINTRAGEN_K -
' -------------------------
'
PROCEDURE vorzeicheneintragen_k
  oktave=4
  xposition=35
  FOR i=1 TO anzahl
    IF i=5 THEN
      DEC oktave
    ELSE
      IF i=6 THEN
        INC oktave
      ENDIF
    ENDIF
    GOSUB ermittledifferenz_okt(gt$,vorzeichen$(art,i,2),0,oktave)
    yposition=90-(2.5*differenz_o)+seite
    PUT xposition,yposition,kreuz$
    xposition=xposition+10
  NEXT i
  xposition=35
  oktave=2
  FOR i=1 TO anzahl
    IF i=5 THEN
      DEC oktave
    ELSE
      IF i=6 THEN
        INC oktave
      ENDIF
    ENDIF
    GOSUB ermittledifferenz_okt(gt$,vorzeichen$(art,i,2),0,oktave)
    yposition=90-(2.5*differenz_o)+seite
    PUT xposition,yposition,kreuz$
    xposition=xposition+10
  NEXT i
RETURN
'
' ----------------------
' - SCHLUESSELZEICHNEN -
' ----------------------
'
PROCEDURE schluesselzeichnen
  COLOR 1
  CIRCLE 20,20,7
  FILL 20,20
  LINE 27,20,20,35
  LINE 28,20,21,35
  GET 10,10,30,40,fschl$
  CLS
  CIRCLE 30,30,7
  LINE 23,30,37,10
  LINE 24,30,38,10
  LINE 37,10,33,8
  LINE 38,10,34,8
  LINE 33,8,30,10
  LINE 34,8,31,10
  LINE 30,10,30,42
  LINE 31,10,31,42
  CIRCLE 31,42,3
  FILL 30,42
  GET 20,5,40,45,gschl$
  CLS
RETURN
'
' ---------------
' - ZEICHNENOTE -
' ---------------
'
PROCEDURE zeichnenote(x,y,l)
  COLOR 1
  SELECT l
  CASE 1
    CIRCLE x,y,5
    CIRCLE x,y,6
  CASE 2
    CIRCLE x,y,5
    CIRCLE x,y,6
    LINE x+5,y,x+5,y-15
    LINE x+6,y,x+6,y-15
  CASE 4
    CIRCLE x,y,5
    LINE x+5,y,x+5,y-15
    LINE x+6,y,x+6,y-15
    FILL x,y+1
    FILL x,y-1
  CASE 8
    CIRCLE x,y,5
    LINE x+5,y,x+5,y-15
    LINE x+6,y,x+6,y-15
    FILL x,y+1
    FILL x,y-1
    LINE x+5,y-15,x+10,y-4
    LINE x+6,y-15,x+11,y-4
  CASE 100
    PUT x,y,kreuz$
  CASE 101
    PUT x,y,b$
  ENDSELECT
RETURN
'
' --------------------
' - @GUELTIGERAKKORD -
' --------------------
'
' prüft, ob die Funktion bekannt ist,
' antwortet via TRUE/FALSE-Flag
'
FUNCTION gueltigerakkord(n$)
  IF n$="T" OR n$="SP" OR n$="DP" OR n$="S" OR n$="D" OR n$="TP" OR n$="D7" THEN
    RETURN 1
  ELSE
    RETURN 0
  ENDIF
ENDFUNC
'
' ***************
' ** Datenteil **
' ***************
'
toene:
DATA c,d,e,f,g,a,h
'
vorzeichen:
DATA f,fis,c,cis,g,gis,d,dis,a,ais,e,eis
DATA h,b,e,es,a,as,d,des,g,ges,c,ces
'
tonleiter:
DATA 1,c
DATA 2,cis,des
DATA 1,d
DATA 2,dis,es
DATA 1,e
DATA 2,eis,f
DATA 2,fis,ges
DATA 1,g
DATA 2,gis,as
DATA 1,a
DATA 2,ais,b
DATA 2,h,ces
