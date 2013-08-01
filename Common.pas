unit Common;

interface

uses
  Windows, Classes, Messages, SysUtils, WinSock;

//”Ú√˚Ω‚Œˆ
function HostToIP(Name: string; var Ip: string): Boolean;

implementation

function HostToIP(Name: string; var Ip: string): Boolean;
var
  wsdata : TWSAData;
  hostName : array [0..255] of AnsiChar;
  hostEnt : PHostEnt;
  addr : PAnsiChar;
begin
  WSAStartup($0101, wsdata);
  try
    gethostname(hostName, sizeof(hostName));
    StrPCopy(hostName, Name);
    hostEnt := gethostbyname(hostName);
    if Assigned(hostEnt) then
      if Assigned(hostEnt^.h_addr_list) then begin
        addr := hostEnt^.h_addr_list^;
        if Assigned(addr) then begin
          IP := Format('%d.%d.%d.%d', [byte(addr [0]),
          byte(addr[1]), byte(addr[2]), byte(addr [3])]);
          Result := True;
        end
        else
          Result := False;
      end
      else
        Result := False
    else begin
      Result := False;
    end;
  finally
    WSACleanup;
  end
end;

end.
