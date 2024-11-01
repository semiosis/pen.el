@echo off
echo Working....
cbsedrv -D -o >nul:
cd cbsedrv >nul:
setd
IF ERRORLEVEL 1 GOTO ABORTED1
setm
IF ERRORLEVEL 1 GOTO ABORTED2
GOTO END
:ABORTED1
cd ..
echo Digital Sound Driver configuration was not completed.
GOTO FINI
:ABORTED2
cd ..
echo Midi Music Driver configuration was not completed.
GOTO FINI
:END
cd..
copy cbsedrv\soundrv.com sound.1
del cbsedrv\soundrv.com >nul:
copy cbsedrv\midpak.adv sound.2
del cbsedrv\midpak.adv >nul:
copy cbsedrv\tmidpak.com sound.3
del cbsedrv\midpak.com >nul:
copy cbsedrv\midpak.ad sound.4
del cbsedrv\midpak.ad >nul:
del cbsedrv\*.c* >nul:
del cbsedrv\*.a* >nul:
del cbsedrv\*.e* >nul:
del cbsedrv\*.o* >nul:
del cbsedrv\*.x* >nul:
del cbsedrv\*.s* >nul:
del cbsedrv\*.b* >nul:
rd cbsedrv >nul:
echo Sound Configuration Complete!
:FINI
