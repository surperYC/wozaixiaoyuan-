@echo off
chcp 65001 >nul
cd /d %~dp0
python WoZaiXiaoYuan.py >> cache\run.log 2>&1
