@echo off
echo %~dp0
call %~dp0\simulator\win32\TestSky.exe -workdir %~dp0
