@echo off
echo %~dp0
start /b %~dp0\simulator\win32\TestSky.exe -workdir %~dp0
