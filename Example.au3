#include "adb.au3"

_AutoItObject_Startup()
$ADB = __ADB_Device()

If $ADB.Scan() Then ReadInfo()
TCPShutdown() ; is Startup By Default in __ADB_Device()
$ADB.Shutdown()
Func ReadInfo()
	ConsoleWrite(@CRLF&'Reading Phone Informtion...')
	Local $cmdArray[0]
	_ArrayAdd($cmdArray,'getprop ro.product.brand')        ; 1
	_ArrayAdd($cmdArray,'getprop ro.product.model')        ; 2
	_ArrayAdd($cmdArray,'getprop ro.semc.product.name')            ; 3
	_ArrayAdd($cmdArray,'getprop ro.product.device')               ; 4
	_ArrayAdd($cmdArray,'getprop ro.hardware')                     ; 5
	_ArrayAdd($cmdArray,'getprop ro.mediatek.platform')            ; 6
	_ArrayAdd($cmdArray,'getprop ro.customer.market.model')        ; 7
	_ArrayAdd($cmdArray,'getprop ro.product.manufacturer')         ; 8
	_ArrayAdd($cmdArray,'getprop ro.build.version.release')        ; 9
	_ArrayAdd($cmdArray,'getprop ro.product.cpu.abi')              ; 10
	_ArrayAdd($cmdArray,'getprop ril.sw_ver')                      ; 11
	_ArrayAdd($cmdArray,'getprop ro.build.PDA')                    ; 12
	_ArrayAdd($cmdArray,'getprop ril.official_cscver')             ; 13
	_ArrayAdd($cmdArray,'getprop ro.csc.country_code')             ; 14
	_ArrayAdd($cmdArray,'getprop ro.csc.sales_code')               ; 15
	_ArrayAdd($cmdArray,'getprop ril.serialnumber')                ; 16
	_ArrayAdd($cmdArray,'getprop ril.rfcal_date')                  ; 17
	_ArrayAdd($cmdArray,'getprop ro.bootloader')                   ; 18
	_ArrayAdd($cmdArray,'getprop ro.product.locale.language')      ; 19
	_ArrayAdd($cmdArray,'getprop ro.product.locale.region')        ; 20
	_ArrayAdd($cmdArray,'getprop persist.sys.timezone')            ; 21
	_ArrayAdd($cmdArray,'getprop gsm.operator.alpha')              ; 22
	_ArrayAdd($cmdArray,'getprop gsm.operator.iso-country')        ; 23
	_ArrayAdd($cmdArray,'')                                        ; 24
	_ArrayAdd($cmdArray,'')                                        ; 25
	_ArrayAdd($cmdArray,'')                                        ; 26
	_ArrayAdd($cmdArray,'')                                        ; 27
	_ArrayAdd($cmdArray,'getprop ro.build.version.security_patch') ; 28
	_ArrayAdd($cmdArray,'getprop ro.boot.verifiedbootstate')       ; 29
	_ArrayAdd($cmdArray,'su -c "echo DevLineTech"')                ; 30
	_ArrayAdd($cmdArray,'getprop ro.build.version.sdk')            ; 31
	_ArrayAdd($cmdArray,'getprop ro.crypto.state')                 ; 32
	_ArrayAdd($cmdArray,'getprop ril.hw_ver')                      ; 33
	_ArrayAdd($cmdArray,'getprop ro.bootmode')                     ; 34
	$Result = AdbCmdArray($cmdArray)

	ConsoleWrite(@CRLF&'Brand : '&$Result[1] & _
	@CRLF&'Model : '&$Result[2]& _
	@CRLF&'Name : '&$Result[3]& _
	@CRLF&'Device : '&$Result[4]& _
	@CRLF&'Hardware : '&$Result[5]& _
	@CRLF&'MTK Platform : '&$Result[6]& _
	@CRLF&'Market Model : '&$Result[7]& _
	@CRLF&'Manufacturer : '&$Result[8]& _
	@CRLF&'Android : '&$Result[9]& _
	@CRLF&'SDK Version : '&$Result[31]& _
	@CRLF&'CPU abi : '&$Result[10]& _
	@CRLF&'Phone version : '&$Result[11]& _
	@CRLF&'HW version : '&$Result[33]& _
	@CRLF&'PDA version : '&$Result[12]& _
	@CRLF&'CSC version : '&$Result[13]& _
	@CRLF&'CSC country code : '&$Result[14]& _
	@CRLF&'CSC sales code : '&$Result[15]& _
	@CRLF&'Phone S/N : '&$Result[16]& _
	@CRLF&'RF cal date : '&$Result[17]& _
	@CRLF&'bootloader : '&$Result[18]& _
	@CRLF&'Language : '&$Result[19]& _
	@CRLF&'Region : '&$Result[20]& _
	@CRLF&'Time zone : '&$Result[21]& _
	@CRLF&'GSM Operator : '&$Result[22]& _
	@CRLF&'ISO country Operator : '&$Result[23])
	$eIMEI = StringSplit($ADB.Shell('dumpsys iphonesubinfo'), "=") ; adb shell service call iphonesubinfo 3 i32 2
	If $eIMEI[0] > 2 Then
		 ConsoleWrite(@CRLF&'IMEI 1 : '& $eIMEI[3])
	Else
		 ConsoleWrite(@CRLF&'IMEI 1 : '& DecIMEI($ADB.Shell('service call iphonesubinfo 3 i32 2')))
	EndIf

	$eIMEI = StringSplit($ADB.Shell('dumpsys iphonesubinfo2'), "=") ; adb shell service call iphonesubinfo 3 i32 2
	If $eIMEI[0] > 2 Then
		ConsoleWrite( @CRLF&'IMEI 2 : '& $eIMEI[3])
	Else
		 ConsoleWrite(@CRLF&'IMEI 2 : '& DecIMEI($ADB.Shell('service call iphonesubinfo 3 i32 1')))
	EndIf

	ConsoleWrite(@CRLF&'Security Patch : '&$Result[28])
	ConsoleWrite(@CRLF&'Boot State : '&$Result[29])

	$isRooted = StringInStr($Result[30], "Rabi3")
	ConsoleWrite(@CRLF&'Rooted : '&$isRooted ? 'Yes' : 'No')

EndFunc

Func AdbCmdArray($Array)
	Local $Cmd = '#!/system/bin/sh' ,  $i =  0
	Do
		$Cmd &=  @CRLF & 'printf $(' & $Array[$i] & ')' & @CRLF & 'printf "^"'
		$i += 1
	Until $i = UBound($Array)
	$ADB.Shell('mkdir /data/')
	$ADB.Shell('mkdir /data/local/')
	$ADB.Shell('mkdir /data/local/tmp/')
	If $ADB.Connect Then
		$ADB.WriteFile('/data/local/tmp/info.sh', $Cmd)
		$ADB.Close
		$Result = $ADB.Shell('sh /data/local/tmp/info.sh')
		Return StringSplit($Result, '^')
	Else
		Return False
	EndIf
EndFunc

Func DecIMEI($Parcel)
Local $array = StringRegExp($Parcel, "[0-9a-f]{8} ", 3)
If UBound($array) <> 10 Then Return
  $IMEI = '0x'
  For $i = 2 To 9
	  $Byte1 = StringMid($array[$i],7,2)
	  $Byte2 = StringMid($array[$i],3,2)
	  $IMEI &= $Byte1&$Byte2
  Next
Return BinaryToString($IMEI)
EndFunc