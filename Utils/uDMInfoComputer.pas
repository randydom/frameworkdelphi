{***********************************************************}
{                                                           }
{                Developed by Daniel Mirrai                 }
{                                                           }
{                Senior Delphi Programmer                   }
{             E-mail: danielmirrai@gmail.com                }
{                   Skype: danielmirrai                     }
{          Phones: +55 (51) 9413-3725 / 3111-2388           }
{         http://www.linkedin.com/in/danielmirrai           }
{          https://www.facebook.com/danielmirrai            }
{                   www.danielmirrai.com                    }
{***********************************************************}

unit uDMInfoComputer;

interface
uses
  NB30, SysUtils, Windows, Variants, uConstantUtils,
  Forms, Registry,
  IdBaseComponent, IdIPWatch;

type
  TDMInfoComputer = class
  private
    class function GetFamilyWindowsSO: string;
    class function GetFamilyNTSO: string;
  public
    class function GetAdapterInfo(aLana: AnsiChar): string;
    class function GetAdress_MAC: string;
    class function GetAdress_IP: string;
    class function GetAdress_IP_Rede: string;
    class function GetName_Processor(aID_Processor: Integer = nCST_Zero): string;
    class function GetName_VideoCard(aID: Integer = nCST_Zero): string;
    class function GetCpuSpeed: string;
    class function GetMotherboard: string;
    class function GetID_Motherboard: Integer;
    class function GetMemory_RAM_Format: string;
    class function GetMemory_RAM: Real;
    class function GetMemory_RAM_MB: Integer;
    class function GetSO: string;
    class function GetName_Computer: string;
    class function GetName_Usuario: string;
    class function GetSerialDisco(Disco: string): string;
    class function GetResolucao: string;
    class function GetSeriaMotherboard: string;
    class function GetBiosInfo: string;

  end;
implementation

uses uDMUtils, uDMHTTP;

{ TObjectActionInfoCompute }

class function TDMInfoComputer.GetAdapterInfo(aLana: AnsiChar):
  string;
var
  vAdapter: TAdapterStatus;
  vNCB: TNCB;
begin
  FillChar(vNCB, SizeOf(vNCB), nCST_Zero);
  vNCB.ncb_command := Char(NCBRESET);
  vNCB.ncb_lana_num := aLana;
  if Netbios(@vNCB) <> Char(NRC_GOODRET) then
  begin
    Result := 'mac n�o encontrado';
    Exit;
  end;

  FillChar(vNCB, SizeOf(vNCB), nCST_Zero);
  vNCB.ncb_command := Char(NCBASTAT);
  vNCB.ncb_lana_num := aLana;
  vNCB.ncb_callname := '*';
  FillChar(vAdapter, SizeOf(vAdapter), nCST_Zero);
  vNCB.ncb_buffer := @vAdapter;
  vNCB.ncb_length := SizeOf(vAdapter);
  if Netbios(@vNCB) <> Char(NRC_GOODRET) then
  begin
    Result := 'mac n�o encontrado';
    Exit;
  end;
  Result := IntToHex(Byte(vAdapter.adapter_address[0]), 2) +
    IntToHex(Byte(vAdapter.adapter_address[1]), 2) +
    IntToHex(Byte(vAdapter.adapter_address[2]), 2) +
    IntToHex(Byte(vAdapter.adapter_address[3]), 2) +
    IntToHex(Byte(vAdapter.adapter_address[4]), 2) +
    IntToHex(Byte(vAdapter.adapter_address[5]), 2);
end;

class function TDMInfoComputer.GetAdress_IP: string;
var
  vIdIPWatch: TIdIPWatch;
begin
  vIdIPWatch := nil;
  try
    vIdIPWatch := TIdIPWatch.Create(nil);
    vIdIPWatch.HistoryEnabled := False;
    Result := vIdIPWatch.LocalIP;
    Result := vIdIPWatch.CurrentIP;
  finally
    TDMUtils.DestroyObject(vIdIPWatch);
  end;
end;

class function TDMInfoComputer.GetAdress_IP_Rede: string;
var
  vReturn, vLocate: string;
  vDMHTTP: TDMHTTP;
  vIndex: Integer;
begin
  Result := sCST_EmptyStr;
  Exit;
  vDMHTTP := nil;
  try
    vDMHTTP := TDMHTTP.Create(nil);
    vDMHTTP.URL := cSiteCaptureIP;
    vReturn := vDMHTTP.SendGet;
    vLocate := 'O MEU IP?';
    vIndex := Pos(vLocate, UpperCase(vReturn));
    if (vIndex > nCST_Zero) then
      Result := Copy(vReturn, vIndex + Length(vLocate) + nCST_One, 13);

    Result := TDMUtils.RemoveCaracter(['>', '<'], Result);
  finally
    TDMUtils.DestroyObject(vDMHTTP);
  end;
end;

class function TDMInfoComputer.GetAdress_MAC: string;
var
  vAdapterList: TLanaEnum;
  vNCB: TNCB;
begin
  Result := sCST_EmptyStr;
  FillChar(vNCB, SizeOf(vNCB), nCST_Zero);
  vNCB.ncb_command := Char(NCBENUM);
  vNCB.ncb_buffer := @vAdapterList;
  vNCB.ncb_length := SizeOf(vAdapterList);
  Netbios(@vNCB);
  if Byte(vAdapterList.length) > 0 then
    Result := GetAdapterInfo(vAdapterList.lana[0]);
end;

class function TDMInfoComputer.GetCpuSpeed: string;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('\Hardware\Description\System\CentralProcessor\0', False) then
    begin
      Result := IntToStr(Reg.ReadInteger('~MHz')) + ' MHz';
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

class function TDMInfoComputer.GetFamilyNTSO: string;
begin
  if Win32MajorVersion <= 4 then
    Result := 'NT'
  else
    if Win32MajorVersion = 5 then
      case Win32MinorVersion of
        0: Result := '2000';
        1: Result := 'XP';
        2: Result := 'Server 2003';
      end
    else
      if (Win32MajorVersion = 6) and (Win32MinorVersion = nCST_Zero) then
        Result := 'Vista'
      else
        Result := 'Windows 7';
end;

class function TDMInfoComputer.GetFamilyWindowsSO: string;
begin
  if Win32MajorVersion = 4 then
    case Win32MinorVersion of
      0: Result := TDMUtils.IIf((Length(Win32CSDVersion) > nCST_Zero) and
          (Win32CSDVersion[1] in ['B', 'C']), '95 OSR2', '95');
      10: Result := TDMUtils.IIf((Length(Win32CSDVersion) > nCST_Zero) and
          (Win32CSDVersion[1] = 'A'), '98 SE', '98');
      90: Result := 'ME';
    end
  else
    Result := '9x version (unknown)';
end;

class function TDMInfoComputer.GetID_Motherboard: Integer;
begin
  Result := nCST_Zero;
end;

class function TDMInfoComputer.GetMemory_RAM: Real;
var
  vMemoryStatus: TMemoryStatus;
begin
  GlobalMemoryStatus(vMemoryStatus);
  Result := vMemoryStatus.dwTotalPhys;
end;

class function TDMInfoComputer.GetMemory_RAM_Format: string;
begin
  Result := TDMUtils.FormatSize(GetMemory_RAM);
end;

class function TDMInfoComputer.GetMemory_RAM_MB: Integer;
var
  vMemory: Real;
begin
  vMemory := GetMemory_RAM;
  Result := TDMUtils.FloatToInt2((vMemory / 1024) / 1024);
end;

class function TDMInfoComputer.GetName_Computer: string;
var
  vPC: Pchar;
  vTamanho: Cardinal;
begin
  vPC := PChar(sCST_Space);
  try
    Result := sCST_EmptyStr;
    vTamanho := 100;
    Getmem(vPC, vTamanho);
    GetComputerName(vPC, vTamanho);
    Result := vPC;
  finally
    FreeMem(vPC);
  end;
end;

class function TDMInfoComputer.GetName_VideoCard(aID: Integer = nCST_Zero): string;
var
  vRegistry: TRegistry;
  vDevice: string;
begin
  Result := sCST_EmptyStr;
  vRegistry := TRegistry.Create(KEY_READ); //ACESSO APENAS LEITURA
  vRegistry.RootKey := HKEY_LOCAL_MACHINE;
  if vRegistry.OpenKeyReadOnly('\HARDWARE\DEVICEMAP\VIDEO\') then
  begin
    vDevice := vRegistry.ReadString('\Device\Video' + IntToStr(aID));
    vDevice := Copy(vDevice, 18, Length(vDevice) - 17); //deleta a string 'registrymachine';
    if vRegistry.OpenKeyReadOnly(vDevice) then
      Result := vRegistry.ReadString('Device Description');
  end;
end;

class function TDMInfoComputer.GetName_Processor(aID_Processor: Integer = nCST_Zero): string;
var
  Reg: TRegistry;
begin
  Result := sCST_EmptyStr;
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('\Hardware\Description\System\CentralProcessor\' + TDMUtils.IntToStr2(aID_Processor), False) then
      Result := Reg.ReadString('Identifier');
  finally
    Reg.Free;
  end;
end;

class function TDMInfoComputer.GetName_Usuario: string;
var
  vUsuario: Pchar;
  vTamanho: Cardinal;
begin
  Result := sCST_EmptyStr;
  vTamanho := 100;
  Getmem(vUsuario, vTamanho);
  GetUserName(vUsuario, vTamanho);
  Result := vUsuario;
  FreeMem(vusuario);
end;

class function TDMInfoComputer.GetMotherboard: string;
begin
  Result := sCST_EmptyStr;
end;

class function TDMInfoComputer.GetResolucao: string;
var
  vWidth,
    vHeigth: string;
begin
  vWidth := INtTOStr(screen.Width);
  vHeigth := IntToStr(screen.Height);
  Result := vWidth + ' x ' + vHeigth;
end;

class function TDMInfoComputer.GetSerialDisco(Disco: string): string;
var
  vSerial: DWord;
  vDirLen, vFlags: DWord;
  vDLabel: array[0..11] of Char;
begin
  Result := sCST_EmptyStr;
  GetVolumeInformation(PChar(disco), vdLabel, 12, @vSerial, vDirLen, vFlags, nil, nCST_Zero);
  Result := IntToHex(vSerial, 8);
end;

class function TDMInfoComputer.GetSeriaMotherboard: string;
var
  a, b, c, d: LongWord;
begin
  asm
    push EAX
    push EBX
    push ECX
    push EDX

    mov eax, 1
    db $0F, $A2
    mov a, EAX
    mov b, EBX
    mov c, ECX
    mov d, EDX

    pop EDX
    pop ECX
    pop EBX
    pop EAX

  end;
  result := inttohex(a, 8) + '-' +
    inttohex(b, 8) + '-' +
    inttohex(c, 8) + '-' +
    inttohex(d, 8);
end;

class function TDMInfoComputer.GetSO: string;
var
  vPlatformId: string;
begin

  // Detecta Plataforma
  case Win32Platform of
    // Teste para familia do windows 95,9X
    VER_PLATFORM_WIN32_WINDOWS: Result := GetFamilyWindowsSO;
    //Teste para familia NT
    VER_PLATFORM_WIN32_NT: Result := GetFamilyNTSO;
  end;
  Result := vPlatformId;
end;

class function TDMInfoComputer.GetBiosInfo: string;
begin
//  Result := GetRegInfoWinNT;
end;

end.
