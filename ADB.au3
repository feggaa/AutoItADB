; #INDEX# =======================================================================================================================
; Title .........: ADB UDF v1.0
; AutoIt Version : 3.3
; Language ......: English , Arabic
; Description ...: Improved ADB library for AutoIt.
; Author(s) .....: Rabi3 Feggaa
; GitHub ........: https://github.com/R3Pro/AutoItADB/
; License .......: LGPL-2.1 License
; ===============================================================================================================================
#include "AutoItObject.au3"

#include-once


Func __ADB_Device($Startup =  True)
	 Local $oObj = _AutoItObject_Create()
	_AutoItObject_AddMethod($oObj, "Startup", __ADB_Device_Startup)
	_AutoItObject_AddMethod($oObj, "Shutdown", __ADB_Device_Shutdown)
	_AutoItObject_AddMethod($oObj, "Connect", __ADB_Device_Connect)
	_AutoItObject_AddMethod($oObj, "Close", __ADB_Device_Desconnect)
	_AutoItObject_AddMethod($oObj, "Test", __ADB_Device_Test)
	_AutoItObject_AddMethod($oObj, "Scan", __ADB_Device_Scan)
	_AutoItObject_AddMethod($oObj, "Reboot", __ADB_Device_Reboot)
	_AutoItObject_AddMethod($oObj, "GetListFiles", __ADB_Device_GetListFiles)
	_AutoItObject_AddMethod($oObj, "StartServer", __ADB_Device_StartServer)
	_AutoItObject_AddMethod($oObj, "Shell", __ADB_Device_Shell)
	_AutoItObject_AddMethod($oObj, "Push", __ADB_Device_Push)
	_AutoItObject_AddMethod($oObj, "Pull", __ADB_Device_Pull)
	_AutoItObject_AddMethod($oObj, "TCPSend", __ADB_Device_Send)
	_AutoItObject_AddMethod($oObj, "Command", __ADB_Device_Command)
	_AutoItObject_AddMethod($oObj, "Struct", __ADB_Struct)
	_AutoItObject_AddMethod($oObj, "WriteFile", __ADB_Device_WriteFile)
	_AutoItObject_AddMethod($oObj, "ReadFile", __ADB_Device_ReadFile)
	_AutoItObject_AddMethod($oObj, "FileExists", __ADB_Device_FileExists)
	_AutoItObject_AddMethod($oObj, "DeleteFile", __ADB_Device_DeleteFile)
	_AutoItObject_AddMethod($oObj, "MoveFile", __ADB_Device_MoveFile)
	_AutoItObject_AddMethod($oObj, "CopyFile", __ADB_Device_CopyFile)
	_AutoItObject_AddMethod($oObj, "ApkInstall", __ADB_Device_ApkInstall)
	_AutoItObject_AddMethod($oObj, "ApkUninstall", __ADB_Device_ApkUninstall)
	_AutoItObject_AddMethod($oObj, "GetListPackages", __ADB_Device_GetListPackages)
	_AutoItObject_AddMethod($oObj, "GetProperty", __ADB_Device_GetProperty)
	_AutoItObject_AddProperty($oObj, "Socket")
	_AutoItObject_AddDestructor($oObj, __ADB_Device_Desconnect)
	If $Startup Then $oObj.Startup
	Return $oObj
EndFunc


Func __ADB_Device_Startup($This)
	Return ShellExecute(@ScriptDir&'/adb.exe','start-server', @ScriptDir, 'open', @SW_HIDE)
EndFunc
Func __ADB_Device_Shutdown($This)
	Return ShellExecute(@ScriptDir&'/adb.exe','kill-server', @ScriptDir, 'open', @SW_HIDE)
EndFunc

Func __ADB_Device_Scan($This)
	ConsoleWrite(@CRLF& "-------------------------"& @HOUR & ':' & @MIN & ':' & @SEC & "-------------------- Start Scan ------------------------------------------")
	$This.Socket = TCPConnect("127.0.0.1", 5037)
    If @error Then Return False
	TCPRecv($This.Socket,4096,0)
	$This.TCPSend("host:devices")
    $Data = TCPRecv($This.Socket,4,0)
	ConsoleWrite(@CRLF & '-------------------- > ' & $data)
	$Recv =  TCPRecv($This.Socket,4096,0)
	ConsoleWrite(@CRLF & '-------------------- > ' & $Recv)
	TCPCloseSocket($This.Socket)
	ConsoleWrite(@CRLF& "--------------------------------------------- End Scan ------------------------------------------")
	If $Recv = "0000" Or $Recv =  '' Then Return False
	Return True 
EndFunc

Func __ADB_Device_Test($This)
	Local $sIPAddress = "127.0.0.1"
	Local $iPort = 5037
	$This.Socket = TCPConnect($sIPAddress, $iPort)
    If @error Then Return False
    ;Connect over usb
	
    $This.TCPSend("host:transport-usb")
    $data = TCPRecv($This.Socket,4,0)
	Sleep(10)
	$data2 = TCPRecv($This.Socket,4096,0)
	TCPCloseSocket($This.Socket)
	
	If StringInStr($data2, '$ADB_VENDOR_KEYS') Or $data2 = '00a2' Or StringInStr($data, '$ADB_VENDOR_KEYS') Or $data = '00a2' Then Return '$ADB_VENDOR_KEYS'
	If 'OKAY' =  StringLeft($data, 4) Then Return 'OKAY'
	Return False
EndFunc

Func __ADB_Device_Connect($This)
	Local $sIPAddress = "127.0.0.1"
	Local $iPort = 5037
	$This.Socket = TCPConnect($sIPAddress, $iPort)
    If @error Then Return False
    ;Connect over usb
	
    $This.TCPSend("host:transport-usb")
    $data = TCPRecv($This.Socket,4096,0)
	TCPRecv($This.Socket,4096,0)
	
	If 'OKAY' =  $data Then Return True
EndFunc

Func __ADB_Device_Reboot($This,$Mode = '')
	Local $isDone = False 
	If $This.Connect Then
		 $isDone = $This.Command('reboot:' & StringLower($Mode), False)
		 $This.Close
		 Return $isDone
	EndIf
	Return SetError(1500, 0, False)
EndFunc

Func __ADB_Device_GetProperty($This,$sKey)
	Local $isDone = False 
	If $This.Connect Then
		 $isDone = $This.Command('shell:getprop ' & $sKey)
		 $This.Close
		 Return $isDone
	EndIf
	Return SetError(1500, 0, False)
EndFunc

Func __ADB_Struct($This,$CMD, $Data)
	$Datalen =  BinaryLen($Data)
	$Strc = DllStructCreate('CHAR Cmd[4];UINT Len;BYTE Path['&$Datalen&']')
	DllStructSetData($Strc,'Cmd', $CMD)
	DllStructSetData($Strc,'Path', $Data)
	DllStructSetData($Strc,'Len',$Datalen)
	$FullLen =  $Datalen + 4 + 4
	Return BinaryMid(DllStructGetDataBinary($Strc),1,$FullLen) 
EndFunc

Func __ADB_Device_Shell($This, $CMD)
	Local $isDone =  False 
	If $This.Connect Then
		 $isDone = $This.Command('shell:' & $CMD)
		 $This.Close
		 Return $isDone
	EndIf
	Return SetError(1500, 0, False)
EndFunc
Func __ADB_Device_GetListFiles($This, $Dir =  '')
	Local $isDone =  False
	$Add =  False
	If $This.Connect Then
		$Data =  $This.Command("shell:ls -1 -l " &$Dir)
		$List = StringSplit(FixData($Data), @CRLF)
		If $List[0] > 3 Then 
			Local $iDir[0][10]
			For $i =  1 To $List[0]
				$Dirs =  StringSplit($List[$i], '<R3|Pro>', 1)
				If $Dirs[0] =  8 Then
					Local $Tmp[1][10] = [[$Dirs[1], $Dirs[2], $Dirs[3], $Dirs[4], $Dirs[5], $Dirs[6], $Dirs[7], $Dirs[8],'','']]
					_ArrayAdd($iDir,$Tmp)
				ElseIf $Dirs[0] =  10 Then
					Local $Tmp[1][10] = [[$Dirs[1], $Dirs[2], $Dirs[3], $Dirs[4], $Dirs[5], $Dirs[6], $Dirs[7], $Dirs[8], $Dirs[9], $Dirs[10]]]
					_ArrayAdd($iDir,$Tmp)
				EndIf
			Next
			$This.Close
			Return $iDir
		Else 
			$This.Close
			Return $Data
		EndIf
	EndIf
	Return SetError(1500, 0, False)
EndFunc


Func __ADB_Device_Push($This, $sFilePath , $RemoteDir, $RemoteName = NameFileFromDir($sFilePath), $ProgressFunc = ProgressFunc)
	If $This.Connect Then
		$This.Command("sync:", False)
		
		TCPSend($This.Socket,$This.Struct('STAT',$RemoteDir))
		TCPRecv($This.Socket,4096)
		
		$RemoteDir =  StringReplace($RemoteDir,'\', '/')
		TCPSend($This.Socket,$This.Struct('SEND', (StringRight($RemoteDir, 1) = '/' ? StringTrimRight($RemoteDir, 1) : $RemoteDir) & '/'&$RemoteName&',33206'))
		TCPRecv($This.Socket,4096)
		$MaxRead = 65536
		$Length = FileGetSize($sFilePath)
		$Loop  = Round($Length / $MaxRead,1)
		$Mod   = Mod($Length,$MaxRead)
		$ProgressFunc(0)
		$hFile = FileOpen($sFilePath, $FO_BINARY)
		If $hFile = -1 Then
			$iError = 1
			$iExtended = _WinAPI_GetLastError()
			$vReturn = -1
		Else
			If $Length > $MaxRead Then
				For $i = 1 To $Loop
					$dTempData = FileRead($hFile,$MaxRead)
					
					TCPSend($This.Socket,Binary($This.Struct('DATA',$dTempData)))
					$Pros =  Round($i * 100 / $Loop, 2)
					$ProgressFunc($Pros)
				Next
			EndIf
			If $Mod > 0 Then
				$dTempData = FileRead($hFile,$Mod)
				TCPSend($This.Socket,Binary($This.Struct('DATA',$dTempData)))
			EndIf
		EndIf
		Sleep(500)
		$ProgressFunc(100)
		TCPRecv($This.Socket,4096)
		
		TCPSend($This.Socket,Binary('0x444f4e457a6d96ff'))
		$Result =  False 
		For $i =  1 To 10
			$Data = BinaryToString(TCPRecv($This.Socket,4096,0))
			If $Data =  'OKAY' Then
				 $Result = True 
				 ExitLoop 
			EndIf
			Sleep(500)
		Next 
		$This.Close
		Return $Result
	EndIf
	Return SetError(1500, 0, False)
EndFunc



Func __ADB_Device_Pull($This, $RemoteFile,$sFilePath =  NameFileFromDir($RemoteFile), $ProgressFunc = ProgressFunc)
	Local  $Result =  True
	$RemoteName = NameFileFromDir($RemoteFile)
	$Strc = DllStructCreate('Byte[4];UINT;UINT;Byte[4]')
	
	$This.Command("sync:", False)
	
	TCPSend($This.Socket,$This.Struct('STAT',$RemoteFile))
	DllStructSetData($Strc,1, TCPRecv($This.Socket,4, 1))
	DllStructSetData($Strc,2,TCPRecv($This.Socket,4, 1))
	DllStructSetData($Strc,3, TCPRecv($This.Socket,4, 1))
	DllStructSetData($Strc,4,TCPRecv($This.Socket,4, 1))
	
	$FileSize = DllStructGetData($Strc,3)  
	
	ProgressOn('','Recive File', $RemoteName,'0% Recving...')
	$Count =  0
	TCPSend($This.Socket,Binary($This.Struct('RECV',$RemoteFile)))
	$hFile = FileOpen($sFilePath, 18)
	If $hFile = -1 Then
		$iError = 1
		$iExtended = _WinAPI_GetLastError()
		$vReturn = -1
	Else
		$ProgressFunc(0)
		Do 
				DllStructSetData($Strc,1, TCPRecv($This.Socket,4, 1))
				If  DllStructGetData($Strc,1) = '0x44415441' Then
					DllStructSetData($Strc,2,TCPRecv($This.Socket,4, 1))
					$Done =  DllStructGetData($Strc,2)
					$Size =  0
					$Read =  4096
					Do 
						If $Size + $Read > $Done Then $Read =  $Done -$Size
						$dTempData = TCPRecv($This.Socket,$Read, 1)
						FileWrite($hFile,$dTempData)
						$Size += BinaryLen($dTempData)
					Until $Size = $Done
					$Count += $Done
					$Pros =  Round($Count * 100 / $FileSize, 2)
					$ProgressFunc($Pros)
				Else
					$Error =  DllStructGetData($Strc,1)
					$Result =  False 
					ExitLoop
				EndIf 
		Until $FileSize =  $Count
		$ProgressFunc(100)
		$Recv =  TCPRecv($This.Socket,4096, 1)
		If $Recv = '0x444f4e4500000000' Then $Result =  True
	EndIf
	ProgressOff()
	FileClose($hFile)
	
	Return $Result  
	
	
EndFunc

Func __ADB_Device_WriteFile($This, $Path, $bData =  '')
	$This.Command("sync:", False)
	
	TCPSend($This.Socket,$This.Struct('STAT',$Path))
	TCPSend($This.Socket,$This.Struct('SEND', $Path&',33206'))
	TCPRecv($This.Socket,4096)
	TCPSend($This.Socket,Binary($This.Struct('DATA',$bData) & '444f4e457a6d96ff'))
	
	$Recv = BinaryToString(TCPRecv($This.Socket,4096))
	If $Recv =  'OKAY' Then Return True 
		
	Return False 
EndFunc
Func __ADB_Device_ReadFile($This, $Path)
	$Data =  $This.Command("shell:cat "&$Path) 
	$TextError =  'cat: '&$Path&': No such file or directory'
	If StringLeft($Data, StringLen($TextError)) = $TextError  Then Return SetError(77,0, False)
	Return $Data
EndFunc


Func __ADB_Device_DeleteFile($This, $sFilePath , $force =  False)
	Local $isDone =  False 
	If $This.Connect Then
		 $isDone = $This.Command('shell:rm ' & ($force ? '-f -rR ': '-rR ') &$sFilePath)
		 $This.Close
		 Return $isDone
	EndIf
	Return SetError(1500, 0, False)
EndFunc

Func __ADB_Device_MoveFile($This, $SOURCE , $DEST , $force =  False)
	Local $isDone = False
	If $This.Connect Then
		 $isDone = $This.Command('shell:mv ' & ($force ? '-f ': ' ') &$SOURCE & ' ' &$DEST)
		 $This.Close
		 Return $isDone
	EndIf
	Return SetError(1500, 0, False)
EndFunc

Func __ADB_Device_CopyFile($This, $SOURCE , $DEST )
	Local $isDone =  False 
	If $This.Connect Then
		 $isDone = $This.Command('shell:cp '&$SOURCE & ' ' &$DEST)
		 $This.Close
		 Return $isDone
	EndIf
	Return SetError(1500, 0, False)
EndFunc

Func __ADB_Device_FileExists($This, $sFilePath)
	Local $isDone =  False 
	If $This.Connect Then
		 $isDone = $This.Command('shell:if [ -e "' & $sFilePath & '" ]; then echo "Found"; else echo "Not Found"; fi')  = "Found"
		 $This.Close
		 Return $isDone
	EndIf
	Return SetError(1500, 0, False)
EndFunc

Func __ADB_Device_ApkInstall($This, $APK_File)
		If $This.push($APK_File, '/data/local/tmp/', 'DevLineAPK.apk') Then
			$Install =  $This.Shell("pm 'install' '/data/local/tmp/DevLineAPK.apk'")
			$eInstall =  ( StringLeft($Install, 7) =  'Success' ? True  : False )
			$This.DeleteFile('/data/local/tmp/DevLineAPK.apk')
			If $eInstall Then  Return True
			Return SetError(1502, 0, False )
		EndIf
		Return SetError(1501, 0, False )
EndFunc
Func __ADB_Device_ApkUninstall($This, $Package, $force =  False)
		$Install =  $This.Shell('pm uninstall '& ($force ? '--user 0 ': ' ') &$Package)
		Return ( StringLeft($Install, 7) =  'Success' ? True  : False )
EndFunc
Func __ADB_Device_GetListPackages($This)
	Local $isDone =  False
	If $This.Connect Then
		$Data =  $This.Command("shell:pm list packages -f")
		$List = StringSplit($Data, @CRLF)
		If $List[0] > 1 Then 
			Local $iDir[0][2]
			For $i =  1 To $List[0]
				$ePkg = StringSplit($List[$i], '=')
				If $ePkg[0] = 2 Then
					$Apk = StringTrimLeft($ePkg[1], 8)
					$Pkg = $ePkg[2] 
					Local $Tmp[1][2] = [[$Pkg,$Apk]]
					_ArrayAdd($iDir,$Tmp)
				EndIf	
			Next
			$This.Close
			Return $iDir
		Else 
			$This.Close
			Return $Data
		EndIf
	EndIf
	Return SetError(1500, 0, False)
EndFunc
	
Func  __ADB_Device_CommandExists($This, $sCommand)
	Local $isDone =  False 
	If $This.Connect Then
		 $isDone = $This.Command('shell:command -v ' & $sCommand & ' > /dev/null 2>&1 && echo "Found" || echo "Not Found"') =  "Found"
		 $This.Close
		 Return $isDone
	EndIf
	Return SetError(1500, 0, False)
EndFunc
	
Func __ADB_Device_Desconnect($This)
	TCPCloseSocket($This.Socket)
EndFunc
	
Func __ADB_Device_StartServer($This)
	
EndFunc
	
Func __ADB_Device_Send($This, $Data)
	TCPSend($This.Socket,adbData($Data))
EndFunc
	
Func __ADB_Device_Command($This, $CMD, $wait =  True )
	$This.TCPSend($CMD)
	$Recv = TCPRecv($This.Socket,4096,0)
	If $Recv <>  'OKAY' Then Return False 
	If $wait Then
		$Data = ''
		Do
			$Data &= TCPRecv($This.Socket,4096,0)
		Until @extended =  1
		Return ($Data = '' ? True : $Data )
	Else 
		Return True 
	EndIf 
EndFunc

Func adbData($s)
    return hex(stringlen($s),4) & $s
EndFunc
Func FixData($eData)
	$eData =  StringReplace(StringReplace($eData,'\ ', '\'), ' ', '<R3|Pro>')
	For $x =  10 To 1 Step -1
		$eData = StringReplace($eData,_StringRepeat('<R3|Pro>',$x), '<R3|Pro>')
	Next
	Return $eData
EndFunc
Func DllStructGetDataBinary($Struct,$min = 0)
	Return DllStructGetData(DllStructCreate("byte["&DllStructGetSize($Struct)-$min&"]",DllStructGetPtr($Struct)),1)
EndFunc
Func NameFileFromDir($Dir)
	Local $iDir = StringSplit(StringReplace($Dir, '\', '/'), '/')
	Return $iDir[$iDir[0]]
EndFunc   ;==>NameFileFromDir
Func ProgressFunc($i)
	
EndFunc
