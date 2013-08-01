program Demo;

uses
  Forms,
  Main in 'Main.pas' {Form4},
  Common in 'Common.pas',
  CmdUtils in 'CmdUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
