@echo off
REM Together App - Web 開發啟動腳本
REM 固定使用 port 8080

echo ========================================
echo Together App - Web Development
echo ========================================
echo.
echo 啟動 Flutter Web (固定 port 8080)...
echo 網址: http://localhost:8080
echo.

flutter run -d chrome --web-port=8080

pause
