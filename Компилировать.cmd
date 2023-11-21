@echo off
chcp 65001
rem Кодировка этого файла UTF-8 без BOM.
del "%~dp0ЗапускалкаTestMem5.exe" 2>nul
"%PROGRAMFILES%\AutoHotkey\Compiler\Ahk2exe.exe"^
  /base "%PROGRAMFILES%\AutoHotkey\v2\AutoHotkey64.exe"^
  /in "%~dp0ЗапускалкаTestMem5.ahk"^
  /icon "%~dp0ЗапускалкаTestMem5.ico"^
  /compress 0