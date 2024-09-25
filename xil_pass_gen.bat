echo off 

set user_list=xilinx01 xilinx02 xilinx03 xilinx04 

set outputFileName=passwords.txt

Setlocal EnableDelayedExpansion
SET _result=

del %outputFileName%

(for %%a in (%user_list%) do (
	call :rndGen;
	echo ****** %%a ****************************
	echo Set password !_result!
	dsquery user -samid %%a | dsmod user -pwd !_result!
	echo login %%a pass !_result! >> %outputFileName%
	echo ""
))
goto :eof

:rndGen
SETLOCAL
Set _RNDLength=8
Set _Alphanumeric=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
Set _Str=%_Alphanumeric%987654321
:_LenLoop
IF NOT "%_Str:~18%"=="" SET _Str=%_Str:~9%& SET /A _Len+=9& GOTO :_LenLoop
SET _tmp=%_Str:~9,1%
SET /A _Len=_Len+_tmp
Set _count=0
SET _RndAlphaNum=
:_loop
Set /a _count+=1
SET _RND=%Random%
Set /A _RND=_RND%%%_Len%
SET _RndAlphaNum=!_RndAlphaNum!!_Alphanumeric:~%_RND%,1!
If !_count! lss %_RNDLength% goto _loop
rem Echo Random string is !_RndAlphaNum!
ENDLOCAL & SET _result=%_RndAlphaNum%

