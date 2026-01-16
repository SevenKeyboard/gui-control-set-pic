#Requires AutoHotkey v1.1.0+
#Include %A_ScriptDir%
#Include .\vendor\Gdip_All.ahk ;  Tested with https://github.com/mmikeww/AHKv2-Gdip/blob/cab5ae291023c790ce4081630b190b5b88409f48/Gdip_All.ahk
;==============================================================
; guiControlSetPic — Sets a Picture control image from file/HBITMAP/HICON with optional resizing via GDI+
;
; GitHub: https://github.com/SevenKeyboard/gui-control-set-pic
; Author: SevenKeyboard Ltd. (2026)
; License: The Unlicense
;
; Documentation / References:
;   Load image into Gui using GDip Issue
;     https://www.autohotkey.com/boards/viewtopic.php?t=94152
;==============================================================

/*
    *wN  *hN  *IconN
      These options has not been implemented yet...
      https://www.autohotkey.com/docs/v1/lib/GuiControl.htm#Blank
*/

class VersionManager_guiControlSetPic
{
    static _ := VersionManager_guiControlSetPic._init()
    _init()    {
        global
        GUICONTROLSETPIC_VERSION := "1.0.0"
    }
}
guiControlSetPic(controlID, value)    {
    static SS_BITMAP:=0xE
    if !dllCall("User32\IsWindow","Ptr",hWnd:=format("{:d}",controlID))    {
        switch (!!regExMatch(controlID,"O)^(.*?):(.*)$",m))
        {
            case true:          guiName:=m[1]           ,assocVar:=m[2]
            default:            guiName:=A_DefaultGui   ,assocVar:=controlID
        }
        guiControlGet hWnd, % guiName ":Hwnd", % assocVar
        if (errorLevel||!hWnd)
            return false
    }
    controlGet style, Style,,, % "ahk_id " hWnd ;  Load image into Gui using GDip Issue  https://www.autohotkey.com/boards/viewtopic.php?t=94152
    if !(style&SS_BITMAP)
        control Style, % "+" SS_BITMAP,, % "ahk_id " hWnd
    ;----------------------------------
    _del:=object()
    if (regExMatch(value,"iO)^HBITMAP:(\*?)(.*)$",m))    {
        hBitmapV:=format("{:d}",trim(m[2]))                 ,_del.hBitmapV:=!m[1]
        pBitmapV:=Gdip_createBitmapFromHBITMAP(hBitmapV)
    }  else if (regExMatch(value,"iO)^HICON:(\*?)(.*)$",m))    {
        hIconV:=format("{:d}",trim(m[2]))                   ,_del.hIconV:=!m[1]
        pBitmapV:=Gdip_createBitmapFromHICON(hIconV)
        hBitmapV:=Gdip_createHBITMAPFromBitmap(pBitmapV)    ,_del.hBitmapV:=true
    }  else if (fileExist(value)~="^[^D]+$")    {
        lpFileName:=value ;  Get Absolute path from relative path  https://www.autohotkey.com/boards/viewtopic.php?f=83&t=67050
        nBufferLength:=dllCall("Kernel32\GetFullPathName", "Str",lpFileName, "UInt",0, "Ptr",0, "Ptr",0, "UInt")
        varSetCapacity(lpBuffer,nBufferLength*(A_IsUnicode?2:1))
        dllCall("Kernel32\GetFullPathName", "Str",lpFileName, "UInt",nBufferLength, "Str",lpBuffer, "Ptr",0, "UInt")
        pBitmapV:=Gdip_createBitmapFromFile(lpBuffer)
        hBitmapV:=Gdip_createHBITMAPFromBitmap(pBitmapV)    ,_del.hBitmapV:=true
    }
    if (!pBitmapV && !hBitmapV)
        return false
    ;----------------------------------
    controlGetPos,,,W,H,, % "ahk_id" hWnd
    widthV:=Gdip_getImageWidth(pBitmapV), heightV:=Gdip_getImageHeight(pBitmapV)
    if (W==widthV && H==heightV)    {
        ret:=setImage(hWnd,hBitmapV) ;  STM_SETIMAGE message  https://learn.microsoft.com/en-us/windows/win32/controls/stm-setimage
    }  else  {
        pBitmap:=Gdip_createBitmap(W,H)
        G:=Gdip_graphicsFromImage(pBitmap)
        Gdip_drawImage(G,pBitmapV, 0,0,W,H, 0,0,widthV,heightV)
        hBitmap:=Gdip_createHBITMAPFromBitmap(pBitmap)
        ret:=setImage(hWnd,hBitmap)
        Gdip_deleteGraphics(G)
        Gdip_disposeImage(pBitmap)
        deleteObject(hBitmap)
    }
    ;----------------------------------
    if (_del.hasKey("pBitmapV"))
        Gdip_disposeImage(pBitmapV)
    if (_del.hasKey("hBitmapV") && _del.hBitmapV)
        deleteObject(hBitmapV)
    if (_del.hasKey("hIconV") && _del.hIconV)
        destroyIcon(hIconV)
    return ret
}