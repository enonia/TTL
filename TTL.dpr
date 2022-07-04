program TTL;

uses
  Forms,
  Main in 'Main.pas' {frmMain},
  Log in '..\MyUnits\Log.pas' {frmLog};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmLog, frmLog);
  Application.Run;
 end.                                
