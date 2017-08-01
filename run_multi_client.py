#!/usr/bin/env python
#-*- coding: utf-8 -*-

################################################
# windows 环境需要把 git.exe 的路径加入环境变量，如 F:\Git\bin
################################################

import os
import sys
from threading import Timer
import platform

SelfPath = os.getcwd()
counter = 1 
total = 3 # 执行次数


def ExecFunc():
    cmd = "start /b run.bat"
    os.system(cmd)
    pass

def TmpFunc(interval):
    global counter
    ExecFunc()

    if counter > 0 and counter < total:
        counter = counter + 1
        t = Timer(interval, TmpFunc, (interval,))
        t.start() 
    pass

def StartTimer(interval):
    t = Timer(interval, TmpFunc, (interval,))
    t.start()
    pass

def main():
    StartTimer(3)
    pass

if __name__ == '__main__':
    main()

