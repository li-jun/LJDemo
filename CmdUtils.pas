unit CmdUtils;

interface

uses
  Classes, Windows, SysUtils, Messages;

function RunDOS(const CommandLine: String): String;

implementation

procedure CheckResult(b: Boolean);
begin
  if not b then
    Raise Exception.Create(SysErrorMessage(GetLastError));
end;

function RunDOS(const CommandLine: String): String;
var
  HRead, HWrite: THandle;
  StartInfo: TStartupInfo;
  ProceInfo: TProcessInformation;
  b: Boolean;
  sa: TSecurityAttributes;
  inS: THandleStream;
  sRet: TStrings;
begin
  Result := '';
  FillChar(sa, sizeof(sa), 0);
  // ��������̳У�������NT��2000���޷�ȡ��������
  sa.nLength := sizeof(sa);
  sa.bInheritHandle := True;
  sa.lpSecurityDescriptor := nil;
  b := CreatePipe(HRead, HWrite, @sa, 0);
  CheckResult(b);

  try
    FillChar(StartInfo, sizeof(StartInfo), 0);
    StartInfo.cb := sizeof(StartInfo);
    StartInfo.wShowWindow := SW_HIDE;
    // ʹ��ָ���ľ����Ϊ��׼����������ļ����,ʹ��ָ������ʾ��ʽ
    StartInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartInfo.hStdError := HWrite;
    StartInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE); // HRead;
    StartInfo.hStdOutput := HWrite;

    b := CreateProcess(nil, // lpApplicationName: PChar
      PChar(CommandLine), // lpCommandLine: PChar
      nil, // lpProcessAttributes: PSecurityAttributes
      nil, // lpThreadAttributes: PSecurityAttributes
      True, // bInheritHandles: BOOL
      CREATE_NEW_CONSOLE, nil, nil, StartInfo, ProceInfo);

    CheckResult(b);
    WaitForSingleObject(ProceInfo.hProcess, INFINITE);

    inS := THandleStream.Create(HRead);
    try
      if inS.Size > 0 then
      begin
        sRet := TStringList.Create;
        sRet.LoadFromStream(inS);
        Result := sRet.Text;
        sRet.Free;
      end;
    finally
      inS.Free;
    end;
  finally
    CloseHandle(HRead);
    CloseHandle(HWrite);
  end;
end;

end.
