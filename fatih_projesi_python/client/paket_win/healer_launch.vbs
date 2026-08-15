' MEBRE AKILLI TAHTA — healer.bat'i GIZLI (pencere acmadan) calistir.
' Zamanlanmis gorev dakikada bir bunu cagirir; boylece healer.bat'in cmd penceresi
' EKRANDA CAKMAZ (0 = gizli pencere). Watchdog/self-heal arka planda sessiz calisir.
CreateObject("WScript.Shell").Run "cmd /c ""C:\ProgramData\MebreSvc\healer.bat""", 0, False
