unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, MMSystem, WaveUtils;

const
  // ** Length of the Speex header identifier */
  SPEEX_HEADER_STRING_LENGTH = 8;

  // ** Maximum number of characters for encoding the Speex version number in the header */
  SPEEX_HEADER_VERSION_LENGTH = 20;

type
  TForm4 = class(TForm)
    pgc1: TPageControl;
    ts1: TTabSheet;
    ts2: TTabSheet;
    mmo1: TMemo;
    pnl1: TPanel;
    btn1: TButton;
    edt1: TEdit;
    btn2: TButton;
    btnSpeexDecode: TButton;
    btn3: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btnSpeexDecodeClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btn3Click(Sender: TObject);
  private
    { Private declarations }
    procedure LogMsg(const AMsg: string);
    procedure CreateWaveFile(AStream: TMemoryStream);
    procedure CreateWaveFileByDLL;
    procedure CreateWaveFileByFileName;
  public
    { Public declarations }
  end;

  SpeexHeader = record
    speex_string: array [1 .. SPEEX_HEADER_STRING_LENGTH] of Byte; // **< Identifies a Speex bit-stream, always set to "Speex   " */
    speex_version: array [1 .. SPEEX_HEADER_VERSION_LENGTH] of Byte;
    // **< Speex version */
    speex_version_id: Integer; // **< Version for Speex (for checking compatibility) */
    header_size: Integer; // **< Total size of the header ( sizeof(SpeexHeader) ) */
    rate: Integer; // **< Sampling rate used */
    mode: Integer; // **< Mode used (0 for narrowband, 1 for wideband) */
    mode_bitstream_version: Integer; // **< Version ID of the bit-stream */
    nb_channels: Integer; // **< Number of channels encoded */
    bitrate: Integer; // **< Bit-rate used */
    frame_size: Integer; // **< Size of frames */
    vbr: Integer; // **< 1 for a VBR encoding, 0 otherwise */
    frames_per_packet: Integer; // **< Number of frames stored per Ogg packet */
    extra_headers: Integer; // **< Number of additional headers after the comments */
    reserved1: Integer; // **< Reserved for future use, must be zero */
    reserved2: Integer; // **< Reserved for future use, must be zero */
  end;

  TDecoderInitProc = procedure; stdcall;
  TDecoderDestroyProc = procedure; stdcall;
  TDecoderDecodeProc = procedure(nbBytes: Integer; data: PAnsiChar;
    out output: array of SmallInt); stdcall;

  TWaveFormat = record
    FieldLabel: array [0 .. 3] of AnsiChar; // "RIFF"
    FieldLen: DWORD; // 从08H开始到文件末尾字节数
    WaveID: array [0 .. 3] of AnsiChar; // "WAVE"  57 41 56 45
    FmtID: array [0 .. 3] of AnsiChar; // "fmt "  66 6D 74 20
    FmtLen: DWORD; // A_LAW  12 00 00 00      PCM  10 00 00 00
    wFormatTag: Word; // format type  A_LAW  06 00            PCM  01 00
    nChannels: Word; // 声道数  01 00
    nSamplesPerSec: DWORD; // sample rate 采样率  40 1F 00 00
    nAvgBytesPerSec: DWORD; // for buffer estimation 每秒平均字节数 40 1F 00 00
    nBlockAlign: Word; // block size of data 块调整 01 00
    wBitsPerSample: Word; // 采样BITS数 08 00
    DataID: array [0 .. 3] of AnsiChar; // "data"  64 61 74 61
    DataLen: DWORD; // 采样数据总字节数
  end;

  TSpeexDecode = function (ASource: PAnsiChar; ASourceLen: Integer; ADest: PAnsiChar;
    ADestLen: Integer): Int64; stdcall;
  TSpeexDecodeByFileName = function (ASourceFile: PAnsiChar; nSourceLen: Integer;
    ADestFile: PAnsiChar; nDestLen: Integer): Integer; stdcall;

var
  Form4: TForm4;

implementation

uses
  Common, CmdUtils;
{$R *.dfm}

procedure TForm4.btn1Click(Sender: TObject);
var
  DestIP: String;
begin
  if HostToIP(edt1.Text, DestIP) then
    mmo1.Lines.Add(edt1.Text + '  ->  ' + DestIP)
  else
    mmo1.Lines.Add('域名解析失败!');
end;

procedure TForm4.btn2Click(Sender: TObject);
var
  cmdLine, cmdResult: String;
  slResult: TStringList;
begin
  cmdLine := Trim(edt1.Text);
  cmdResult := RunDOS(cmdLine);
  OutputDebugString(PWideChar(cmdResult));
  mmo1.Lines.Add(cmdResult);
end;

procedure TForm4.btn3Click(Sender: TObject);
begin
   SndPlaySound(PChar('d:\2222.wav'), SND_FILENAME Or SND_ASYNC);
end;

procedure TForm4.btnSpeexDecodeClick(Sender: TObject);
const
  frame_size = 160;
  READ_BUFF_SIZE = 20;
var
  sDllName, sFileName: String;
  hLib: Cardinal;
  DecoderInit: TDecoderInitProc;
  DecoderDestroy: TDecoderDestroyProc;
  DecoderDecode: TDecoderDecodeProc;
  mStream, waveStream: TMemoryStream;
  Buff: array [1 .. frame_size] of SmallInt;
  ReadBuff: array [1 .. READ_BUFF_SIZE] of AnsiChar;
  nCount: Integer;
  WaveFileFormat: TWaveFormat;
begin
  if edt1.Text = '' then
    Exit;
  CreateWaveFileByFileName;
  Exit;

  // 引用DLL
  sDllName := 'd:\projects\Code\C++\HqewSpeex\Release\HqewSpeex.dll';
  hLib := LoadLibrary(PWideChar(sDllName));
  if hLib <= 0 then
  begin
    LogMsg('装载动态库文件失败：' + IntToStr(GetLastError()));
  end;

  try
    DecoderInit := GetProcAddress(hLib, '_decoder_init@0');
    DecoderDestroy := GetProcAddress(hLib, '_decoder_dispose@0');
    DecoderDecode := GetProcAddress(hLib, '_decoder_decode@12');
    if Assigned(DecoderInit) then
    begin
      DecoderInit;
      try
        if Assigned(DecoderDecode) then
        begin
          mStream := TMemoryStream.Create;
          waveStream := TMemoryStream.Create;
          try
            mStream.LoadFromFile(edt1.Text);
            nCount := SizeOf(SpeexHeader);
            //初始化Wave格式
            WaveFileFormat.FieldLabel := 'RIFF';
            WaveFileFormat.FieldLen := $0001060A;
            WaveFileFormat.WaveID := 'WAVE';
            WaveFileFormat.FmtID := 'fmt ';
            WaveFileFormat.FmtLen := SizeOf(PCMWAVEFORMAT);
            WaveFileFormat.wFormatTag := WAVE_FORMAT_PCM;
            WaveFileFormat.nChannels := 1;
            WaveFileFormat.nSamplesPerSec := 8000;
            WaveFileFormat.nAvgBytesPerSec := 1 * 8000 * 16 div 8;
            WaveFileFormat.nBlockAlign := 8000 * 16 div 8;
            WaveFileFormat.wBitsPerSample := 16;
            WaveFileFormat.DataID := 'data';
            WaveFileFormat.DataLen := (mStream.Size - nCount) * 8 * SizeOf(SmallInt);
            //WaveFileFormat.FieldLen := WaveFileFormat.DataLen + SizeOf(TWaveFormat);
            waveStream.Write(WaveFileFormat, SizeOf(TWaveFormat));

            mStream.Position := nCount;
            while nCount < mStream.Size do
            begin
              mStream.ReadBuffer(ReadBuff[1], READ_BUFF_SIZE);
              DecoderDecode(READ_BUFF_SIZE, @ReadBuff[1], Buff);
              waveStream.Write(Buff[1], frame_size * SizeOf(SmallInt));
              nCount := nCount + READ_BUFF_SIZE;
            end;
            if waveStream.Size > 0 then
            begin
              sFileName := 'd:\1111.wav';
              if FileExists(sFileName) then
                DeleteFile(sFileName);
              waveStream.SaveToFile(sFileName);
              LogMsg('解码成功！');
              CreateWaveFile(waveStream);
            end;
          finally
            mStream.Free;
            waveStream.Free;
          end;
        end;
      finally
        if Assigned(DecoderDestroy) then
          DecoderDestroy;
      end;
    end;
  finally
    FreeLibrary(hLib);
  end;

end;

procedure TForm4.CreateWaveFile(AStream: TMemoryStream);
var
  ckRIFF, ckData: TMMCKInfo;
  mmIO: HMMIO;
  WaveFormatEx: TWaveFormatEx;
  fDataOffset: Integer;
  mStream: TMemoryStream;
begin
  mStream := TMemoryStream.Create;
  try
    SetPCMAudioFormatS(@WaveFormatEx, Mono16Bit8000Hz);
    mmIO := CreateStreamWaveAudio(mStream, @WaveFormatEx, ckRIFF, ckData);
    if mmIO <> 0 then
    begin
      fDataOffset := mmioSeek(mmIO, 0, SEEK_CUR);
      AStream.Position := 0;
      mmioWrite(mmIO, AStream.Memory, AStream.Size);
      mmioAscend(mmIO, @ckData, 0);
      mmioAscend(mmIO, @ckRIFF, 0);
      mmioClose(mmIO, 0);
      mmIO := 0;
    end;
    mStream.SaveToFile('d:\2222.wav');
  finally
    mStream.Free;
  end;

end;

procedure TForm4.CreateWaveFileByDLL;
var
  sDllName: String;
  hLib: Cardinal;
  SpeexDecode: TSpeexDecode;
  mStream: TMemoryStream;
  pSource, pDest: PAnsiChar;
  nSourceLen, nDestLen: Integer;
  nResultLen: Int64;
begin
  sDllName := ExtractFilePath(ParamStr(0)) + 'SpeexCodec.dll';
  hLib := LoadLibrary(PWideChar(sDllName));
  if hLib <= 0 then
  begin
    LogMsg('装载动态库文件失败：' + IntToStr(GetLastError()));
    Exit;
  end;

  try
    SpeexDecode := GetProcAddress(hLib, 'SpeexDecode');
    if Assigned(SpeexDecode) then
    begin
      mStream := TMemoryStream.Create;
      try
        mStream.LoadFromFile(edt1.Text);
        nSourceLen := mStream.Size + 1;
        
        GetMem(pSource, nSourceLen);
        if pSource = nil then
        begin
          LogMsg('申请内存失败1!');
          Exit;
        end;
        ZeroMemory(pSource, nSourceLen);

        nDestLen := (mStream.Size - SizeOf(SpeexHeader)) * 8 * SizeOf(SmallInt) +
          SizeOf(TWaveFormatEx) + 1 + 1024;  //18
        GetMem(pDest, nDestLen);
        if pDest = nil then
        begin
          LogMsg('申请内存失败2!');
          Exit;
        end;
        ZeroMemory(pDest, nDestLen);

        mStream.Position := 0;
        mStream.Read(pSource^, mStream.Size);

        nResultLen := SpeexDecode(pSource, nSourceLen, pDest, nDestLen);
        if nResultLen <= 0 then
        begin
          OutputDebugString(PWideChar('调用失败：' + IntToStr(nResultLen)));
          Exit;
        end;
        mStream.Clear;
        mStream.Write(pDest^, nResultLen);
        mStream.SaveToFile('d:\3333.wav');
      finally
        if pSource <> nil then
          FreeMem(pSource, nSourceLen);
        if pDest <> nil then
          FreeMem(pDest, nDestLen);
        mStream.Free;
      end;
    end;
  finally
    FreeLibrary(hLib);
  end;
end;

procedure TForm4.CreateWaveFileByFileName;
var
  sDllName: String;
  hLib: Cardinal;
  SpeexDecodeByFileName: TSpeexDecodeByFileName;
  mStream: TMemoryStream;
  pSource, pDest: PAnsiChar;
  SourceFile, DestFile: AnsiString;
  nSourceLen, nDestLen: Integer;
  nResultLen: Int64;
begin
  sDllName := ExtractFilePath(ParamStr(0)) + 'SpeexCodec.dll';
  hLib := LoadLibrary(PWideChar(sDllName));
  if hLib <= 0 then
  begin
    LogMsg('装载动态库文件失败：' + IntToStr(GetLastError()));
    Exit;
  end;

  try
    SpeexDecodeByFileName := GetProcAddress(hLib, 'SpeexDecodeByFileName');
    if Assigned(SpeexDecodeByFileName) then
    begin
      SourceFile := edt1.Text;
      DestFile := 'd:\4444.wav';
      pSource := PAnsiChar(SourceFile);
      pDest := PAnsiChar(DestFile);

      nResultLen := SpeexDecodeByFileName(pSource, Length(SourceFile), pDest,
        Length(DestFile));
      if nResultLen <= 0 then
      begin
        OutputDebugString(PWideChar('调用失败：' + IntToStr(nResultLen)));
        Exit;
      end;

    end;
  finally
    FreeLibrary(hLib);
  end;
end;

procedure TForm4.FormShow(Sender: TObject);
begin
  edt1.Text := 'e:\Share\Temp\2013-06-17-17-04-23_speex.caf';
end;

procedure TForm4.LogMsg(const AMsg: string);
begin
  mmo1.Lines.Add(AMsg);
end;

end.
