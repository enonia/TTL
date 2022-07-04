unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, ExtCtrls, StrUtils;

type

  TLineState = ( LSSTART, LSO1, LSX1, LSO2, LSX2, LSEND, LSERR, LSINUSE );
  TNextRC = (LTWO, LONE);


  PLine = ^TLine;
  TLine= class
  public
    iSiz : Cardinal;
    iLen : Cardinal;
    BL   : Cardinal;
    LS   : TLineState;
    constructor Create(iSize :Integer);
    function clone:TLine;
    function next(var RC:TNextRC):TLine;
    function show:String;
    function numx :Cardinal;
    function numo :Cardinal;
    function startswith(BLFrag :Cardinal; iFraglen: Integer):Boolean;
    function contains(BLShape :Cardinal; BLMask: Cardinal):Boolean;
  end;

  TListSortCompare = function (Item1: TLine; Item2: TLine): Integer;


  TGridLine=class
  public
    LinePool    :TList;
    MatchLines  :TList;
    FullLines   :TList;
    BL          :Cardinal;
    MASK        :Cardinal;
    UBL         :Cardinal;
    UMASK       :Cardinal;
    iSiz        :Integer;

    constructor Create(PoolLines :TList; var LinesFull: TList);
    destructor Destroy; override;
    procedure  SetP(CH:String; Idx:Integer);
    procedure  Reset;
    procedure  CalcUnique;
  end;

  TAction = ( ACTSET, ACTPUSH, ACTPOPPT, ACTPOPNP );

  TActionTrack =class
  public
    Action:TAction;
    Col     :Integer;
    Row     :Integer;
    FVal    :String;
    TVal    :String;
    constructor Create(aAction: TAction; aCol:Integer = -1; aRow:Integer = -1;  aFVal:String = ' '; aTVal:String = ' '); overload;
    constructor Create(aAction: TAction; aFVal:String = ' '); overload;
  end;

  TfrmMain = class(TForm)
    Panel2: TPanel;
    StringGrid1: TStringGrid;
    Panel3: TPanel;
    cboWidth: TComboBox;
    Size: TLabel;
    cboHeight: TComboBox;
    Label1: TLabel;
    btnClear: TButton;
    btnPush: TButton;
    btnPop: TButton;
    btnSolve: TButton;
    chkLog: TCheckBox;
    chkHint: TCheckBox;
    Panel4: TPanel;
    chkSlow: TCheckBox;
    btnLoad: TButton;
    btnSave: TButton;
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    cbBacktracking: TCheckBox;
    btnBack: TButton;
    pnlMsg: TPanel;
    lblCheck: TLabel;
    btnForward: TButton;
    btnTracker: TButton;
    procedure StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;  Shift: TShiftState; X, Y: Integer);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cboSizeClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnPushClick(Sender: TObject);
    procedure btnPopClick(Sender: TObject);
    procedure btnSolveClick(Sender: TObject);
    procedure chkLogClick(Sender: TObject);
    procedure chkHintClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnForwardClick(Sender: TObject);
    procedure btnTrackerClick(Sender: TObject);
  private
    { Private-Deklarationen }
    sLogfile :String;


    procedure initgrid;
    function IsValid(iCol:Integer; iRow:Integer; sSym:String):Boolean;
    procedure AddToLog(sOut:String);
    function doChecks:Boolean;
    function getValStr:String;
    procedure putValStr(sVal:String; bNoTrack :Boolean);
    function findFreePos(var iCol:Integer; var iRow:Integer):Boolean;

    function TrySet( iCol:Integer; iRow:Integer; sSym:String ): Boolean;
    procedure push(bNoTrack :Boolean = False);
    procedure pop(bNoPut:Boolean; bNoTrack :Boolean = False);
    function test ( iCol:Integer; iRow:Integer; sSym:String ): Boolean;
    Procedure testlog ( iCol:Integer; iRow:Integer; sSym:String); overload;
    Procedure testlog ( iCol:Integer; iRow:Integer; sSym:String; bOK:Boolean ); overload;
    function genLines(iLineSize:Cardinal):TList;
    function matcha( var LAktCols:TList; var LAktRows: TList; var LCols:TList; var LRows:TList):Boolean;
    function getBKColor(iCol:Integer; iRow:Integer):TColor;
    procedure SetCell(iCol:Integer; iRow:Integer; sSym:String; bNoTrack :Boolean = False);


  public
    { Public-Deklarationen }
  end;

var
  frmMain      :TfrmMain;
  Stack        :Array of String;
  Lines        :Array of TLine;
  iGlobCnt     :Integer;
  Tracker      :Array of TActionTrack;
  TrackIdx     :Integer;



implementation

uses Log;

{$R *.dfm}


const

CHX = 'X';
CHO = 'O';
CHN = ' ';

COLCNT : Word = 6;
ROWCNT : Word = 6;

var
  LRows :TList;
  LCols :TList;

  LFullRows :TList;
  LFullCols :TList;

  SelectCol :Integer;
  SelectRow :Integer;




function SortByShow(Item1, Item2: TLine): Integer;
begin
  Result := AnsiCompareText(Item1.show,Item2.show);
end;

constructor TGridLine.create(PoolLines :TList; var LinesFull :TList);
var
  i:Integer;

begin
  FullLines := LinesFull;
  LinePool := TList.Create;
  MatchLines := TList.Create;
  for i := 0 to PoolLines.Count-1 do
    MatchLines.Add(PoolLines.Items[i]);

  iSiz := TLine(MatchLines.Items[0]).iSiz;
  BL := 0;
  MASK := 0;
  UBL := 0;
  UMASK := 0;
end;


destructor TGridLine.Destroy();
begin
  MatchLines.Clear;
  MatchLines.Free;
  LinePool.Clear;
  LinePool.Free;
  inherited Destroy;
end;



procedure  TGridLine.SetP(CH:String; Idx:Integer);
var
  i   :Integer;

begin

  if CH = CHN then
  begin
    MASK := MASK and not (1 shl Idx);
    BL   := BL and not (1 shl Idx);
    for i := LinePool.Count-1 downto 0 do
    begin
      if TLine(LinePool.Items[i]).contains(BL,MASK) then
      begin
        MatchLines.Add(LinePool.Items[i]);
        LinePool.Remove(LinePool.Items[i]);
      end;
    end;
  end
  else
  begin
    if AnsiUpperCase(CH) = CHX then BL := BL or (1 shl Idx);
    MASK := MASK or ( 1 shl Idx);

    for i := MatchLines.Count-1 downto 0 do
    begin
      if not TLine(MatchLines.Items[i]).contains(BL,MASK) then
      begin
        LinePool.Add(MatchLines.Items[i]);
        MatchLines.Remove(MatchLines.Items[i]);
      end;
    end;
  end;
  CalcUnique;
end;

procedure  TGridLine.reset;
var
  i   :Integer;
begin
  for i := LinePool.Count-1 downto 0 do
  begin
    MatchLines.Add(LinePool.Items[i]);
    LinePool.Remove(LinePool.Items[i]);
  end;
  MASK := 0;
  BL := 0;
  UMASK := 0;
  UBL := 0;
end;

procedure  TGridLine.CalcUnique;
var
  iBit :Cardinal;
  i    :Integer;
  j    :Integer;
  bFound :Boolean;

  tmpList :TList;


begin
  UBL  := 0;
  UMASK := 0;


  tmpList := TList.Create;
  for i := 0 to FullLines.Count-1 do
  begin
    for j := 0 to MatchLines.Count-1 do
    begin
      if TLine(MatchLines.Items[j]).BL = TLine(FullLines.Items[i]).BL then
      begin
        tmpList.Add( MatchLines.Items[j] );
        MatchLines.Remove(MatchLines.Items[j]);
        break;
      end;
    end;
  end;


  for i:= 0 to iSiz-1 do
  begin
    if  (( MASK and (1 shl i) ) = 0) and ( MatchLines.Count > 0 ) then
    begin
      bFound := True;
      iBit :=  (TLine(MatchLines.Items[0]).BL shr i) and 1;
      for j := 1 to MatchLines.Count-1 do
        if ((TLine(MatchLines.Items[j]).BL shr i) and 1) <> iBit then
        begin
          bFound := False;
          break;
        end;
      if bFound then
      begin
        UMASK := UMASK or (1 shl i);
        UBL := UBL or ( iBit shl i);
      end;
    end;
  end;


  while tmpList.Count > 0 do
  begin
    MatchLines.Add(tmpList.Items[0]);
    tmpList.Remove(tmpList.Items[0]);
  end;
  tmpList.Free;

end;




constructor TLine.Create(iSize :Integer);
begin
  iSiz := iSize;
  iLen := 0;
  BL := 0;
  LS := LSSTART;
end;

function TLine.clone:TLine;
var
  Clon : TLine;
begin
  Clon := TLine.Create(Self.iSiz);
  Clon.BL := Self.BL;
  Clon.LS := Self.LS;
  Clon.iLen := Self.iLen;
  result :=  Clon;
end;

function TLine.next(var RC:TNextRC):TLine;
var
  Clon :TLine;

begin
  Clon := Self.clone;

  if iLen < iSiz then
  begin
    RC := LTWO;
    if LS = LSSTART then
    begin
      LS := LSO1;
      Clon.BL := (Clon.BL or(1 shl iLen));
      CLon.LS := LSX1;
    end
    else if LS = LSO1 then
    begin
      LS := LSO2;
      Clon.BL := (Clon.BL or (1 shl iLen));
      CLon.LS := LSX1;
    end
    else if LS = LSX1 then
    begin
      LS := LSO1;
      Clon.BL := (Clon.BL or (1 shl iLen));
      CLon.LS := LSX2;
    end
    else if LS = LSO2 then
    begin
      LS := LSX1;
      BL := (BL or (1 shl iLen));
      RC := LONE;
    end
    else if LS = LSX2 then
    begin
      LS := LSO1;
      RC := LONE;
    end ;
    Inc(iLen);
    Inc(Clon.iLen);

    if iLen = iSiz then
    begin
      if numx = iSiz div 2 then
        LS := LSEND
      else
        LS := LSERR;
      if (RC <> LONE) and ( Clon.numx = iSiz div 2 ) then
        Clon.LS := LSEND
      else
        Clon.LS := LSERR;
    end;
  end;

  if RC = LONE then
  begin
    Clon.free;
    Clon := nil;
  end;

  result := Clon;
end;



function TLine.show:String;
var
  i:Integer;
  sRes :String;

begin
  sRes := '';
  for i := 0 to iLen-1 do
  begin
    if BL and (1 shl i) <> 0 then
      sRes := sRes + 'X'
    else
      sRes := sRes + 'O';
  end;
  result :=  sRes;
end;


function TLine.numx:Cardinal;
var
  i:Integer;

begin
  result := 0;
  for i := 0 to iLen-1 do
    if BL and (1 shl i) <> 0 then Inc(result)

end;

function TLine.numo:Cardinal;
var
  i:Integer;

begin
  result := 0;
  for i := 0 to iLen-1 do
    if BL and (1 shl i) = 0 then Inc(result)
end;

function TLine.contains(BLShape :Cardinal; BLMask: Cardinal):Boolean;
begin
   Result := (BL AND BLMask) = BLShape;
end;



function TLine.startswith(BLFrag :Cardinal; iFraglen: Integer):Boolean;
var
  i     :Integer;
  iMask :Cardinal;

begin
  iMask := 0;
  for i := 0 to iFraglen-1 do
     iMask := iMask or (1 shl i);

  Result := Self.contains(BLFrag,iMask);
end;


constructor TActionTrack.Create(aAction: TAction; aCol:Integer; aRow:Integer; aFVal:String; aTVal:String);
begin
  Action := aAction;
  Col := aCol;
  Row := aRow;
  FVal := aFVal;
  TVal := aTVal;
end;

constructor TActionTrack.Create(aAction: TAction; aFVal:String);
begin
  Action := aAction;
  Col := -1;
  Row := -1;
  FVal := aFVal;
  TVal := '';
end;




PROCEDURE TfrmMain.AddToLog(sOut:String);
var
   fd:System.Text;

begin

   if frmLog <> nil then
   begin
     frmLog.lbLog.Items.Add(sOut);
     frmLog.lbLog.ItemIndex := frmLog.lbLog.Items.Count-1;
   end;

   if sLogfile <> '' then
   begin
     AssignFile(fd,sLogfile);
     {$I-}append(fd);{$I+}
     if IOResult <> 0 then {$I-}rewrite(fd);{$I+}
     writeln(fd,FormatDateTime('dd.mm.yy hh:nn:ss ',Now)+sOut);
     CloseFile(fd);
   end;
end;


function TfrmMain.getValStr:String;
var
  iCol :Integer;
  iRow :Integer;
begin
  Result := '';
  with StringGrid1 do
    for iRow := 1 to RowCount-1 do
      for iCol := 1 to ColCount-1 do
        Result := Result + Cells[iCol,iRow];
end;



procedure TfrmMain.SetCell( iCol:Integer; iRow:Integer; sSym:String; bNoTrack :Boolean );
var
  GL       : TGridLine;
  i        : Integer;
  FULLMASK : Cardinal;


begin
  with StringGrid1 do
  begin

    if not bNoTrack and (sSym <> Cells[iCol,iRow] ) then
    begin
      // Strip Tracking
      if TrackIdx < Length(Tracker) then SetLength(Tracker,TrackIdx+1);
      Inc(TrackIdx);
      SetLength(Tracker,TrackIdx+1);
      Tracker[TrackIdx] := TActionTrack.Create(ACTSET,iCol,iRow,Cells[iCol,iRow],sSym);
    end;

    if ((AnsiUpperCase(sSym)=CHO) and (AnsiUpperCase(Cells[iCol,iRow])=CHX)) OR ((AnsiUpperCase(sSym)=CHX) and (AnsiUpperCase(Cells[iCol,iRow])=CHO))  then
      SetCell(iCol,iRow,CHN,bNoTrack);

    pnlMsg.Caption := Format('SET[%d,%d] from ''%s'' to ''%s'' ',[iCol,iRow,Cells[iCol,iRow],sSym]);

    Cells[iCol,iRow] := sSym;

    GL :=  (Objects[iCol,0] as TGridLine);
    FULLMASK := Cardinal((1 shl GL.iSiz)-1);
    if (sSym = CHN) and (GL.MASK = FULLMASK) then
    begin
      // war voll
      for i:= 0 to LFullCols.Count-1 do
      begin
        if TLine(LFullCols.Items[i]).BL = GL.BL then
        begin
          LFullCols.Remove(LFullCols.Items[i]);
          break;
        end;
      end;
      for i:= 1 to ColCount-1 do (Objects[i,0] as TGridLine).CalcUnique;
    end;

    GL.SetP(sSym,iRow-1);

    if GL.MASK = FULLMASK then
    begin
      // ist voll
      for i:= 0 to GL.MatchLines.Count-1 do
      begin
        if TLine(GL.MatchLines.Items[i]).BL = GL.BL then
        begin
          LFullCols.Add(GL.MatchLines.Items[i]);
          break;
        end;
      end;
      for i:= 1 to ColCount-1 do (Objects[i,0] as TGridLine).CalcUnique;
    end;


    GL := (Objects[0,iRow] as TGridLine);
    FULLMASK := Cardinal((1 shl GL.iSiz)-1);
    if (sSym = CHN) and (GL.MASK = FULLMASK) then
    begin
      // war voll
      for i:= 0 to LFullRows.Count-1 do
      begin
        if TLine(LFullRows.Items[i]).BL = GL.BL then
        begin
          LFullRows.Remove(LFullRows.Items[i]);
          break;
        end;
      end;
      for i:= 1 to RowCount-1 do (Objects[0,i] as TGridLine).CalcUnique;
    end;

    GL.SetP(sSym,iCol-1);

    if GL.MASK = FULLMASK then
    begin
      // ist voll
      for i:= 0 to GL.MatchLines.Count-1 do
      begin
        if TLine(GL.MatchLines.Items[i]).BL = GL.BL then
        begin
          LFullRows.Add(GL.MatchLines.Items[i]);
          break;
        end;
      end;
      for i:= 1 to RowCount-1 do (Objects[0,i] as TGridLine).CalcUnique;
    end;
  end;
end;


function TfrmMain.TrySet( iCol:Integer; iRow:Integer; sSym:String ): Boolean;
begin

  if IsValid(iCol,iRow,sSym) then
  begin
    SetCell(iCol,iRow,sSym);
    Result :=  True;
  end
  else
    Result := False;

  if chkSlow.Checked then sleep(500);

  StringGrid1.Repaint;
  Application.ProcessMessages;
end;



function TfrmMain.doChecks:Boolean;
var
  iCol    :Integer;
  iRow    :Integer;
  bOK     :Boolean;
  bFertig :Boolean;
  sSym    :String;

begin
  bOK := True;
  bFertig := false;
  while bOK and not bFertig do
  begin
    bFertig := True;
    with StringGrid1 do
    begin
      for iCol := 1 to ColCount-1 do
      begin
        for iRow := 1 to RowCount-1 do
        begin
          sSym := CHN;
          if ((Objects[iCol,0] as TGridLine).UMASK and (1 shl (iRow-1))) <> 0 then
          begin
            if ((Objects[iCol,0] as TGridLine).UBL and (1 shl (iRow-1))) <> 0 then
              sSym := CHX
            else
              sSym := CHO;
          end
          else if ((Objects[0,iRow] as TGridLine).UMASK and (1 shl (iCol-1))) <> 0 then
          begin
            if ((Objects[0,iRow] as TGridLine).UBL and (1 shl (iCol-1))) <> 0 then
              sSym := CHX
            else
              sSym := CHO;
          end;
          if bOK and (sSym <> CHN) then
          begin
            bOK := TrySet(iCol,iRow,sSym);
            bFertig := false;
          end;
          if not bOK then break;
        end;
      end
    end;
  end;
  Result := bOK;
end;



procedure TfrmMain.push(bNoTrack :Boolean);
var
  iSP  :Integer;

begin

  if not bNoTrack then
  begin
    // Strip Tracking
    if TrackIdx < Length(Tracker) then SetLength(Tracker,TrackIdx+1);
    Inc(TrackIdx);
    SetLength(Tracker,TrackIdx+1);
    Tracker[TrackIdx] := TActionTrack.Create(ACTPUSH,'');
  end;

  pnlMsg.Caption := Format('PUSH ',[]);

  iSP := Length(Stack);
  SetLength(Stack,iSP+1);
  Stack[iSP] := getValStr;
end;


procedure TfrmMain.putValStr(sVal:String; bNoTrack:Boolean);
var
  iCol :Integer;
  iRow :Integer;
  iIdx :Integer;

begin
  iIdx := 1;
  with StringGrid1 do
  begin

    LFullRows.Clear;
    LFullCols.Clear;

    for iRow := 1 to RowCount-1 do
      for iCol := 1 to ColCount-1 do
        Cells[iCol,iRow] := CHN;

    for iCol := 1 to ColCount-1 do
      (Objects[iCol,0] as TGridLine).Reset;
    for iRow := 1 to RowCount-1 do
      (Objects[0,iRow] as TGridLine).Reset;


    for iRow := 1 to RowCount-1 do
      for iCol := 1 to ColCount-1 do
      begin
        SetCell(iCol,iRow,AnsiMidStr(sVal,iIdx,1),bNoTrack);
        Inc(iIdx);
      end;

     Repaint;
  end;

  FormResize(frmMain);

  //setupgrid(bNoTrack);
end;


procedure TfrmMain.pop(bNoPut:Boolean; bNoTrack :Boolean);
var
  iSP  :Integer;
  sVal :String;

begin

  if not bNoTrack then
  begin
    // Strip Tracking
    if TrackIdx < Length(Tracker) then SetLength(Tracker,TrackIdx+1);
    Inc(TrackIdx);
    SetLength(Tracker,TrackIdx+1);
    if bNoPut then
    begin
      Tracker[TrackIdx] := TActionTrack.Create(ACTPOPNP,Stack[Length(Stack)-1]);
    end
    else
    begin
      Tracker[TrackIdx] := TActionTrack.Create(ACTPOPPT,getValStr());
    end;
  end;

  iSP := Length(Stack)-1;
  sVal := Stack[iSP];
  if not bNoPut then putValStr(sVal,True);
  SetLength(Stack,iSP);

  if bNoPut then
    pnlMsg.Caption := Format('POP(NoPut)',[])
  else
    pnlMsg.Caption := Format('POP(Put)',[]);


end;



procedure TfrmMain.StringGrid1MouseDown(Sender: TObject;  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  iCol     :Integer;
  iRow     :Integer;
  GL       :TGridLine;
  i        :Integer;
  sPattern :String;


begin
  SelectCol := -1;
  SelectRow := -1;

  with (Sender as TStringGrid) do
    begin
    if Button =  mbLeft then
    begin
      MouseToCell( X, Y, iCol, iRow );
      if (iCol > 0) AND (iRow > 0) then
      begin
        if Cells[iCol,iRow] = CHN then SetCell(iCol,iRow,CHX)
        else if  AnsiUpperCase(Cells[iCol,iRow]) = CHX then SetCell(iCol,iRow,CHO)
        else  SetCell(iCol,iRow,CHN);
        Refresh;
      end
      else if (iCol = 0) and ( iRow = 0 ) then
      begin
        Repaint;
      end
      else if iCol = 0 then
      begin
        SelectRow := iRow;
        Repaint;
        GL := (Objects[0,iRow] as TGridLine);
        AddToLog(Format('Zeile=%d Pool=%d Match=%d Full=%d BL=%d MASK=%d UBL=%d UMASK=%d',[iRow,GL.LinePool.Count,GL.MatchLines.Count, GL.FullLines.Count, GL.BL, GL.Mask, GL.UBL, GL.UMask]));
        for i := 0 To GL.MatchLines.Count-1 do
          AddToLog(Format('%s', [ TLine(GL.MatchLines.Items[i]).show] ));
        AddToLog('=======');
      end
      else if iRow = 0 then
      begin
        SelectCol := iCol;
        Repaint;
        GL := (Objects[iCol,0] as TGridLine);
        AddToLog(Format('Spalte=%d Pool=%d Match=%d Full=%d BL=%d MASK=%d UBL=%d UMASK=%d',[iCol,GL.LinePool.Count,GL.MatchLines.Count, GL.FullLines.Count, GL.BL, GL.Mask, GL.UBL, GL.UMask]));

        for i := 0 To GL.MatchLines.Count-1 do
          AddToLog(Format('%s', [ TLine(GL.MatchLines.Items[i]).show] ));
        AddToLog('=======');
      end
    end
    else if Button =  mbRight then
    begin
      MouseToCell( X, Y, iCol, iRow );
      if (iCol > 0) AND (iRow > 0) then
      begin
        if Cells[iCol,iRow] = CHN then SetCell(iCol,iRow,CHO)
        else if  AnsiUpperCase(Cells[iCol,iRow]) = CHO then SetCell(iCol,iRow,CHX)
        else  SetCell(iCol,iRow,CHN);
        Refresh;
      end
      else if iCol = 0 then
      begin
        sPattern := '';
        for i:=0 to ColCount-2 do
        begin
          if ((Objects[0,iRow] as TGridLine).UMASK and (1 shl i)) <> 0 then
          begin
            if ((Objects[0,iRow] as TGridLine).UBL and (1 shl i)) <> 0 then
              sPattern := sPattern + CHX
            else
              sPattern := sPattern + CHO;
          end
          else if ((Objects[0,iRow] as TGridLine).MASK and (1 shl i)) <> 0 then
          begin
            if ((Objects[0,iRow] as TGridLine).BL and (1 shl i)) <> 0 then
              sPattern := sPattern + 'x'
            else
              sPattern := sPattern + 'o';
          end
          else
            sPattern := sPattern + '.';
        end;
        AddToLog(Format('Zeile=%d Pattern=%s',[iRow,sPattern]));
      end
      else if iRow = 0 then
      begin
        sPattern := '';
        for i:=0 to RowCount-2 do
        begin
          if ((Objects[iCol,0] as TGridLine).UMASK and (1 shl i)) <> 0 then
          begin
            if ((Objects[iCol,0] as TGridLine).UBL and (1 shl i)) <> 0 then
              sPattern := sPattern + CHX
            else
              sPattern := sPattern + CHO;
          end
          else if ((Objects[iCol,0] as TGridLine).MASK and (1 shl i)) <> 0 then
          begin
            if ((Objects[iCol,0] as TGridLine).BL and (1 shl i)) <> 0 then
              sPattern := sPattern + 'x'
            else
              sPattern := sPattern + 'o';
          end
          else
            sPattern := sPattern + '.';
        end;
        AddToLog(Format('Spalte=%d Pattern=%s',[iCol,sPattern]));
      end
    end;
    if IsValid( iCol, iRow, Cells[iCol,iRow] ) then
      lblCheck.Caption := 'OK!'
    else
      lblCheck.Caption := 'NOK!';
  end;

end;



function TfrmMain.getBKColor(iCol:Integer; iRow:Integer):TColor;
const
  COLOR_SELECT = TColor($CAB3AA);
  COLOR_DUPLO  = TColor($8CFF8C);

var
  kolor :TColor;
  GLS   :TGridLine;
  GLP   :TGridLine;
  i     :Integer ;
  bFound:Boolean;



begin
  kolor := TColor($FFFFFF);
  with StringGrid1 do
  begin
    if (iCol = 0) and (iRow = 0) then
      kolor := TColor($000000)
    else if SelectCol > 0 then
    begin
      if iCol = SelectCol then kolor := COLOR_SELECT;
      GLS := Objects[SelectCol,0] as TGridLine;
      if GLS.MASK = Cardinal((1 shl GLS.iSiz)-1) then
      begin
        bFound := false;
        // komplett -> suche Spalten, die enthalten sind
        for i := 1 to ColCount-1 do
        begin
          if (i <> SelectCol) then
          begin
            GLP := Objects[i,0] as TGridLine;
            if ((GLS.BL AND GLP.MASK) = (GLP.BL AND GLP.MASK)) and (GLP.MASK <> 0) then
            begin
              bFound := true;
              if iCol = i then
              begin
                kolor := COLOR_DUPLO;
                break;
              end;
            end;
          end;
        end;
        if (iCol = SelectCol) and bFound then kolor := COLOR_DUPLO;
      end
      else if GLS.MASK <> 0 then
      begin
        bFound := false;
        // inkomplett -> suche komplette Spalten in denen die selektierte enthalten ist
        for i := 1 to ColCount-1 do
        begin
          if (i <> SelectCol) then
          begin
            GLP := Objects[i,0] as TGridLine;
            if (GLP.MASK = Cardinal((1 shl GLP.iSiz)-1)) and ((GLS.BL AND GLS.MASK) = (GLP.BL AND GLS.MASK)) then
            begin
              bFound := true;
              if iCol = i then
              begin
                kolor := COLOR_DUPLO;
                break;
              end;
            end;
          end
        end;
        if (iCol = SelectCol) and bFound then kolor := COLOR_DUPLO;
      end;
    end
    else if SelectRow > 0 then
    begin
      if iRow = SelectRow then kolor := COLOR_SELECT;
      GLS := Objects[0,SelectRow] as TGridLine;
      if GLS.MASK = Cardinal((1 shl GLS.iSiz)-1) then
      begin
        bFound := false;
        // komplett -> suche Zeilen, die enthalten sind
        for i := 1 to RowCount-1 do
        begin
          if (i <> SelectRow) then
          begin
            GLP := Objects[0,i] as TGridLine;
            if ((GLS.BL AND GLP.MASK) = (GLP.BL AND GLP.MASK)) and (GLP.MASK <> 0) then
            begin
              bFound := true;
              if iRow = i then
              begin
                kolor := COLOR_DUPLO;
                break;
              end;
            end;
          end;
        end;
        if (iRow = SelectRow) and bFound then kolor := COLOR_DUPLO;
      end
      else if GLS.MASK <> 0 then
      begin
        bFound := false;
        // inkomplett -> suche komplette Zeilen in denen die selektierte enthalten ist
        for i := 1 to RowCount-1 do
        begin
          if (i <> SelectRow) then
          begin
            GLP := Objects[0,i] as TGridLine;
            if (GLP.MASK = Cardinal((1 shl GLP.iSiz)-1)) and ((GLS.BL AND GLS.MASK) = (GLP.BL AND GLS.MASK)) then
            begin
              bFound := true;
              if iRow = i then
              begin
                kolor := COLOR_DUPLO;
                break;
              end;
            end;
          end
        end;
        if (iRow = SelectRow) and bFound then kolor := COLOR_DUPLO;
      end;
    end;
  end;

  Result := kolor;
end;



procedure TfrmMain.StringGrid1DrawCell(Sender: TObject; ACol,  ARow: Integer; Rect: TRect; State: TGridDrawState);
const
  COLOR_T       =  TColor($0000FF);
  COLOR_O       =  TColor($FF80BF);
  COLOR_X       =  TColor($000000);
  COLOR_E       =  TColor($808080);
  COLOR_U       =  TColor($B0B0B0);


var
  sText  :String;
  sHint  :String;
  iW     :Integer;

  iPW    :Integer;
  iDO    :Integer;
  iDX    :Integer;

  iO     :Integer;
  iX     :Integer;
  i      :Integer;

  OColor :TColor;
  XColor :TColor;

begin
  with (Sender as TStringGrid) do
  begin

    iW := DefaultColWidth;

    iPW :=  iW div 16;
    iDO :=  iW div 8;
    iDX :=  iW div 5;

    Canvas.Brush.Color := getBKColor(ACol,ARow);
    Canvas.Pen.Width := 1;
    Canvas.Font.Size := Font.Size div 2;
    Canvas.Font.Style  := [fsBold];
    sText := Cells[ACol,ARow];


(*
    if ( sText = AnsiLowerCase(CHO) ) OR ( sText = AnsiLowerCase(CHX) ) then
      Canvas.Font.Color := TColor($FF0000)
    else if sText = CHO then
      Canvas.Font.Color := COLOR_O
    else
      Canvas.Font.Color := TColor($000000);
 *)

    Canvas.FillRect(Rect);

    if (ARow = 0) and (ACol > 0) then
    begin
      Canvas.Pen.Color := TColor($000000);
      Canvas.Pen.Width :=  2;

      Canvas.MoveTo(rect.Left,rect.Bottom);
      Canvas.LineTo(rect.Right,rect.Bottom);

      iO := 0;
      iX := 0;
      for i:=1 to RowCount-1 do
      begin
        if AnsiUpperCase(Cells[ACol,i]) = CHO then Inc(iO)
        else if AnsiUpperCase(Cells[ACol,i]) = CHX then Inc(iX);
      end;
      if iO+iX = (RowCount-1) then
      begin
        OColor := COLOR_E;
        XColor := COLOR_E;
      end
      else
      begin
        OColor := COLOR_O;
        XColor := COLOR_X;
      end;

      Canvas.Font.Color := XColor;
      Canvas.TextOut(Rect.Left+trunc(0.2*iW),Rect.Top+trunc(0.1*iW),Format('%d',[iX]));
      Canvas.Font.Color :=  OColor;
      Canvas.TextOut(Rect.Left+trunc(0.53*iW),Rect.Top+trunc(0.55*iW),Format('%d',[iO]));
    end
    else if (ACol = 0) and (ARow > 0) then
    begin
      Canvas.Pen.Color := TColor($000000);
      Canvas.Pen.Width :=  2;

      Canvas.MoveTo(rect.Right,rect.Top);
      Canvas.LineTo(rect.Right,rect.Bottom);

      iO := 0;
      iX := 0;
      for i:=1 to ColCount-1 do
      begin
        if AnsiUpperCase(Cells[i,ARow]) = CHO then Inc(iO)
        else if AnsiUpperCase(Cells[i,ARow]) = CHX then Inc(iX);
      end;
      if iO+iX = (ColCount-1)  then
      begin
        OColor := COLOR_E;
        XColor := COLOR_E;
      end
      else
      begin
        OColor := COLOR_O;
        XColor := COLOR_X;
      end;

      Canvas.Font.Color := XColor;
      Canvas.TextOut(Rect.Left+trunc(0.2*iW),Rect.Top+trunc(0.1*iW),Format('%d',[iX]));
      Canvas.Font.Color :=  OColor;
      Canvas.TextOut(Rect.Left+trunc(0.53*iW),Rect.Top+trunc(0.55*iW),Format('%d',[iO]));
    end
    else if (ACol = 0) and (ARow = 0) then
    begin
      //Canvas.Brush.Color := TColor($000000);
      Canvas.FillRect(Rect);
      
      Canvas.Pen.Color := TColor($808080);
      Canvas.Pen.Width :=  1;
      Canvas.MoveTo(rect.Left,rect.TOP);
      Canvas.LineTo(rect.Right ,rect.Bottom);

      Canvas.Font.Color := TColor($FFFFFF);
      Canvas.TextOut(Rect.Left+trunc(0.53*iW),Rect.Top+trunc(0.1*iW),Format('%d',[(RowCount-1) div 2]));
      Canvas.TextOut(Rect.Left+trunc(0.15*iW),Rect.Top+trunc(0.56*iW),Format('%d',[(ColCount-1) div 2]))
    end
    else if AnsiUpperCase(sText) = CHO then
    begin
      if sText = AnsiLowerCase(CHO) then Canvas.Pen.Color := COLOR_T else  Canvas.Pen.Color := COLOR_O;
      Canvas.Pen.Width :=  iPW;
      Canvas.Ellipse(rect.Left+iDO ,rect.Bottom-iDO ,rect.Right-iDO ,rect.Top+iDO );
    end
    else if AnsiUpperCase(sText) = CHX then
    begin
      if sText = AnsiLowerCase(CHX) then Canvas.Pen.Color := COLOR_T else  Canvas.Pen.Color := COLOR_X;
      Canvas.Pen.Width :=  iPW;
      Canvas.MoveTo(rect.Left+iDX ,rect.Bottom-iDX);
      Canvas.LineTo(rect.Right-iDX ,rect.Top+iDX);
      Canvas.MoveTo(rect.Left+iDX ,rect.Top+iDX);
      Canvas.LineTo(rect.Right-iDX ,rect.Bottom-iDX);
    end
    else if chkHint.Checked then
    begin
      sHint := CHN;
      if ((Objects[ACol,0] as TGridLine).UMASK and (1 shl (ARow-1))) <> 0 then
      begin
        if ((Objects[ACol,0] as TGridLine).UBL and (1 shl (ARow-1))) <> 0 then
          sHint := CHX
        else
          sHint := CHO;
      end
      else if ((Objects[0,ARow] as TGridLine).UMASK and (1 shl (ACol-1))) <> 0 then
      begin
        if ((Objects[0,ARow] as TGridLine).UBL and (1 shl (ACol-1))) <> 0 then
          sHint := CHX
        else
          sHint := CHO;
      end;
      Canvas.Pen.Color := COLOR_U;
      if sHint = CHO then
      begin
        Canvas.Pen.Width :=  iPW;
        Canvas.Ellipse(rect.Left+iDO ,rect.Bottom-iDO ,rect.Right-iDO ,rect.Top+iDO );
      end
      else if sHint = CHX then
      begin
        Canvas.Pen.Width :=  iPW;
        Canvas.MoveTo(rect.Left+iDX ,rect.Bottom-iDX);
        Canvas.LineTo(rect.Right-iDX ,rect.Top+iDX);
        Canvas.MoveTo(rect.Left+iDX ,rect.Top+iDX);
        Canvas.LineTo(rect.Right-iDX ,rect.Bottom-iDX);
      end
    end;
    Canvas.Font.Color := TColor($FFFFFF);
  end;
end;


procedure TfrmMain.FormResize(Sender: TObject);
var
  iWidth  :Integer;
  iHeight :Integer;

  iW      :Integer;
  iH      :Integer;

begin



  iWidth  :=  Panel2.Width -10;
  iHeight :=  Panel2.Height -10;

  iW :=  iWidth div (COLCNT+1);
  iH  :=   iHeight div (ROWCNT+1);


  if iW > iH then
    iW := iH
  else
    iH := iW;

  iWidth := (COLCNT+1) * ( iW  );
  iHeight := (ROWCNT+1)  * ( iH );
  StringGrid1.Width := iWidth + 1;
  StringGrid1.Height := iHeight + 1;

  StringGrid1.DefaultColWidth := iW - 1;
  StringGrid1.DefaultRowHeight := iH - 1;
  Stringgrid1.Font.Size := trunc( iW div 2 );

end;

procedure TfrmMain.initgrid;
var
  iCol :Integer;
  iRow :Integer;

begin
  with StringGrid1 do
  begin
    ColCount := COLCNT+1;
    RowCount := ROWCNT+1;

    LRows := GenLines(COLCNT);
    LCols := GenLines(ROWCNT);

    LFullRows := TList.Create;
    LFullCols := TList.Create;


    for iCol := 1 to ColCount-1 do
      Objects[iCol,0] := TGridLine.Create(LCols,LFullCols);
    for iRow := 1 to RowCount-1 do
      Objects[0,iRow] := TGridLine.Create(LRows,LFullRows);

    for iCol := 1 to ColCount-1 do
    begin
      for iRow := 1 to RowCount-1 do
      begin
        if Cells[iCol,iRow] = '' then Cells[iCol,iRow] := CHN;
        SetCell(iCol,iRow,Cells[iCol,iRow]);
      end;
    end;

    Repaint;
  end;
  FormResize(frmMain);
end;



procedure TfrmMain.FormCreate(Sender: TObject);
begin
  sLogfile := 'TTL.log';
  initgrid;

  SetLength(Stack,0);
  SetLength(Tracker,0);
  TrackIdx := -1;

  (Sender As TWinControl).DoubleBuffered := true;
  (StringGrid1 As TWinControl).DoubleBuffered := true;


end;

procedure TfrmMain.cboSizeClick(Sender: TObject);
begin
   if (cboWidth.Text <> '') and (cboHeight.Text <> '') then
   begin
     COLCNT := StrToInt(cboWidth.Text);
     ROWCNT := StrToInt(cboHeight.Text);
   end;
   initgrid;
end;

function TfrmMain.IsValid(iCol:Integer; iRow:Integer; sSym:String):Boolean;
var
  bOK  :Boolean;
  iX   :Integer;
  iY   :Integer;
  iOSum :Integer;
  iXSum :Integer;
  iLine :Integer;
  sPreSym :String;
  sAktSym :String;
  sSave :String;

begin

  bOK := True;



  with StringGrid1 do
  begin
    sSave := Cells[iCol,iRow];
    Cells[iCol,iRow] := sSym;
    // Row-Check
    sPreSym := CHN;
    iOSum := 0;
    iXSum := 0;
    iLine := 0;
    for iX := 1 to ColCount-1 do
    begin
      sAktSym := Cells[iX,iRow];
      if sAktSym <> CHN then
      begin
        if sAktSym <> sPreSym then
          iLine := 0;
        Inc(iLine);
        if AnsiUpperCase(sAktSym) = CHX then Inc(iXSum);
        if AnsiUpperCase(sAktSym) = CHO then Inc(iOSum);
      end
      else
        iLine := 0;
      if iLine >  2 then
      begin
        bOK := false;
        break;
      end;
      sPreSym := sAktSym;
    end;
      if (iXSum > ColCount div 2) then
      begin
        bOK := false;
      end;
      if (iOSum > ColCount div 2)  then
      begin
        bOK := false;
      end;

    if bOK then
    begin
      sPreSym := CHN;
      iOSum := 0;
      iXSum := 0;
      iLine := 0;
      // Col-Check
      for iY := 1 to RowCount-1 do
      begin
        sAktSym := Cells[iCol,iY];
        if sAktSym <> CHN then
        begin
          if sAktSym <> sPreSym then
            iLine := 0;
          Inc(iLine);
          if AnsiUpperCase(sAktSym) = CHX then Inc(iXSum);
          if AnsiUpperCase(sAktSym) = CHO then Inc(iOSum);
        end
        else
          iLine := 0;
        if iLine >  2 then
        begin
          bOK := false;
          break;
        end;
        sPreSym := sAktSym;
      end;
      if (iXSum > (RowCount-1) div 2) then
      begin
        bOK := false;
      end;
      if (iOSum > (RowCount-1) div 2)  then
      begin
        bOK := false;
      end;

    end;

    // duplicate column check
    if bOK then
    begin
      for iX := 1 to ColCount-1 do
      begin
        if iX <> iCol then
        begin
          bOK := false;
          for iY := 1 to RowCount-1 do
          begin
            if ( Cells[iX,iY] <> Cells[iCol,iY] ) or ( Cells[iCol,iY] = CHN ) then
            begin
              bOK := True;
              break;
            end;
          end;
          if not bOK then
          begin
            break;
          end;
        end;
      end;
    end;

    // duplicate row check
    if bOK then
    begin
      for iY := 1 to RowCount-1 do
      begin
        if iY <> iRow then
        begin
          bOK := false;
          for iX := 1 to ColCount-1 do
          begin
            if ( Cells[iX,iY] <> Cells[iX,iRow] ) or ( Cells[iX,iRow] = CHN ) then
            begin
              bOK := True;
              break;
            end;
          end;
          if not bOK then
          begin
            break;
          end;
        end;
      end;
    end;


    Cells[iCol,iRow] := sSave;
  end;
  result := bOK;
end;




procedure TfrmMain.btnClearClick(Sender: TObject);
var
  iCol :Integer;
  iRow :Integer;

begin
  with StringGrid1 do
  begin
    LFullCols.Clear;
    LFullRows.Clear;
    ColCount := COLCNT+1;
    RowCount := ROWCNT+1;
    for iCol := 1 to ColCount-1 do
    begin
      TGridLine(Objects[iCol,0]).Reset;
      for iRow := 1 to RowCount-1 do
        Cells[iCol,iRow]  := CHN;
    end;
    for iRow := 1 to RowCount-1 do  TGridLine(Objects[0,iRow]).Reset;
    Repaint;
  end;

  SetLength(Stack,0);
  SetLength(Tracker,0);
  TrackIdx := -1;
  pnlMsg.Caption := '';

  FormResize(frmMain);
end;

procedure TfrmMain.btnPushClick(Sender: TObject);
begin
  push;
end;

procedure TfrmMain.btnPopClick(Sender: TObject);
begin
  if length(Stack) > 0 then
    pop(false);
end;



function TfrmMain.findFreePos(var iCol:Integer; var iRow:Integer):Boolean;
var
  iX   :Integer;
  iY   :Integer;
  bDone:Boolean;

begin
  with StringGrid1 do
  begin
    bDone := false;
    if cbBacktracking.checked then
    begin
      for iX := 1 to ColCount-1 do
      begin
        for iY := 1 to RowCount-1 do
        begin
          if Cells[iX,iY] = CHN then
          begin
            iCol := iX;
            iRow := iY;
            bDone := True;
            break;
          end;
        end;
        if bDone then
          break;
      end;
    end;
  end;
  Result := bDone;

end;

Procedure TfrmMain.testlog ( iCol:Integer; iRow:Integer; sSym:String);
var
  sMsg :String;
  i    :Integer;
begin
  sMsg := '';
  for i:= 0 to length(Stack) do sMsg := sMsg + ' ';
  sMsg := sMsg + Format('Teste %s auf Pos(%d,%d)...',[sSym,iCol,iRow]);
  AddToLog(sMsg);

end;

Procedure TfrmMain.testlog ( iCol:Integer; iRow:Integer; sSym:String; bOK:Boolean );
var
  sMsg :String;
  i    :Integer;
begin
  sMsg := '';
  for i:= 0 to length(Stack) do sMsg := sMsg + ' ';


  sMsg := sMsg + Format('Teste %s auf Pos(%d,%d):',[sSym,iCol,iRow]);
  if bOK then
  begin
     sMsg := sMsg + 'OK';
     StringGrid1.Cells[iCol,iRow] := AnsiUpperCase(sSym);
  end
  else
     sMsg := sMsg + 'FAIL';

  AddToLog(sMsg);

end;




function TfrmMain.test ( iCol:Integer; iRow:Integer; sSym:String ): Boolean;
var
  iX   :Integer;
  iY   :Integer;
  bOK  :Boolean;


begin
  push;
  testlog(iCol,iRow,sSym);

  bOK := TrySet(iCol,iRow,sSym);
  if bOK  then
    bOK := doChecks;

  if  bOK  and findFreePos(iX,iY) then
  begin
    bOK := test(iX,iY,AnsiLowerCase(CHX));
    if not bOK then
      bOK := test(iX,iY,AnsiLowerCase(CHO));
  end;

  testlog(iCol,iRow,sSym,bOK);

  pop(bOK);

  result := bOK;
end;



procedure TfrmMain.btnSolveClick(Sender: TObject);
var
  iX   :Integer;
  iY   :Integer;
  bOK  :Boolean;

begin
  bOK := doChecks;

  if bOK and findFreePos(iX,iY) then
  begin
    bOK := test(iX,iY,AnsiLowerCase(CHX));
    if not bOK then
      bOK := test(iX,iY,AnsiLowerCase(CHO));
  end;

  AddToLog(Format('fertig! bOK:%d',[ord(bOK)]));

end;





function TfrmMain.genLines(iLineSize:Cardinal):TList;
var
  L           :TList;
  LineA       :TLine;
  LineB       :TLine;
  sMsg        :String;
  aRC         :TNextRC;
  i           :Integer;
  j           :Integer;
  iAktSize    :Integer;
  iGood       :Integer;
  iTotal      :Integer;

begin

  iGood := 0;
  iTotal := 0;


  L := TList.Create();
  LineA := TLine.Create(iLineSize);
  L.Add(LineA);


  for i := 1 to iLineSize do
  begin
    iAktSize := L.Count;
    for j := iAktSize-1  downto 0 do
    begin
      LineA := L.Items[j];
      LineB := LineA.next(aRC);

      if (LineA.iLen = iLineSize) then
        Inc(iTotal);

      if LineA.LS = LSEND then
        Inc(iGood)
      else if LineA.LS = LSERR then
      begin
        L.Remove(LineA);
        LineA.Free;
      end;

      if ( aRC = LTWO )  then
      begin
        L.Add(LineB);

        if (LineB.iLen = iLineSize) then
          Inc(iTotal);

        if LineB.LS = LSEND then
          Inc(iGood)
        else if LineB.LS = LSERR then
        begin
          L.Remove(LineB);
          LineB.Free;
        end;
      end;
    end;
  end;

  L.Sort(@SortbyShow);

  Result := L;

  sMsg := Format('Good/Total: %d/%d', [iGood,iTotal]);
  AddToLog(sMsg);

end;




function TfrmMain.matcha( var LAktCols:TList; var LAktRows: TList; var LCols:TList; var LRows:TList):Boolean;
var
  bRC :Boolean;

  iBit:Cardinal;
  i   :Integer;
  iX  :Integer;
  iY  :Integer;
  iMaxX :Integer;
  iMaxY :Integer;
  BLFrag   :Cardinal;
  Line   :TLine;
  sMsg  :String;



begin
  bRC := False;
  BLFrag := 0;
  iMaxX := TLine(LRows.Items[0]).iSiz;
  iMaxY := TLine(LCols.Items[0]).iSiz;

  iX := LAktCols.Count;
  iY := LAktRows.Count;

  if ( iX = iMaxX ) and ( iY = iMaxY ) then
  begin
    Inc(iGlobCnt);
    for i := 0 To LAktRows.Count-1 do
    begin
      sMsg := Format('%s', [ TLine(LAktRows.Items[i]).show] );
      AddToLog(sMsg);
    end;
    sMsg := '';
    for i:= 0 to iMaxX do
      sMsg := sMsg + '=';
    AddToLog(Format('%s(%d)',[sMsg,iGlobCnt]));
  end
  else if (iY < iMaxY) and ((iY < iX) or ( iX = iMaxX )) then
  begin
    // neue Zeilen
    for i :=0 to iX-1 do
    begin
      iBit :=  ( TLine(LAktCols.Items[i]).BL and ( 1 shl iY ) ) shr iY;
      BLFrag := BLfrag OR (iBit shl i);
    end;

    for i := 0 to LRows.Count-1 do
    begin
      if TLine(LRows.Items[i]).startswith(BLFrag,iX) and ( TLine(LRows.Items[i]).LS = LSEND ) then
      begin
        Line := TLine(LRows.Items[i]);
        Line.LS := LSINUSE;
        LAktRows.Add(Line);
        bRC := matcha( LAktCols,LAktRows,LCols,LRows );
        LAktRows.Remove(Line);
        Line.LS := LSEND;
      end;
    end;
  end
  else 
  begin
    // neue Spalten
    for i :=0 to iY-1 do
    begin
      iBit :=  ( TLine(LAktRows.Items[i]).BL and ( 1 shl iX ) ) shr iX;
      BLFrag := BLfrag OR (iBit shl i);
    end;
    for i := 0 to LCols.Count-1 do
    begin
      if TLine(LCols.Items[i]).startswith(BLFrag,iY) and ( TLine(LCols.Items[i]).LS = LSEND ) then
      begin
        Line := TLine(LCols.Items[i]);
        Line.LS := LSINUSE;
        LAktCols.Add(Line);
        bRC := matcha( LAktCols,LAktRows,LCols,LRows );
        LAktCols.Remove(Line);
        Line.LS := LSEND;
      end;
    end;
  end;

  result := bRC;
end;





procedure TfrmMain.chkLogClick(Sender: TObject);
begin
  if (Sender As TCheckBox).Checked then
    frmLog.Show
  else
    frmLog.Hide;
end;



procedure TfrmMain.chkHintClick(Sender: TObject);
begin
  StringGrid1.Repaint;
end;


procedure TfrmMain.btnSaveClick(Sender: TObject);
var
  fd_out     :System.Text;
  iRow       :Integer;
  iCol       :Integer;
  iRC        :Integer;
  sDateiname :String;
  sOut       :String;



begin
  SaveDialog1.InitialDir := '.\';
  SaveDialog1.Filter := 'TTL-Dateien (*.ttl)|*.ttl';

  if SaveDialog1.Execute then
  begin
    sDateiname := SaveDialog1.Filename;
    if (Pos('.',sDateiname) = 0) OR (Pos('.',ReverseString(sDateiname)) > 4 ) then
      sDateiname := sDateiname + '.ttl';
  end
  else
    exit;

  system.Assign(fd_out,sDateiname);

  {$I-} System.Reset(fd_out); {$I-}
  iRC := IOResult;
  if iRC = 0 then
  begin
    CloseFile(fd_out);
    if Application.MessageBox('Ausgabedatei ist bereits vorhanden. Überschreiben?','Bestätigung',MB_YESNO) = IDNO then
      exit;
  end;

  try
    system.rewrite(fd_out);
  finally
    ;
  end;

  Screen.Cursor := crHourglass;

  with StringGrid1 do
  begin
    for iRow := 1 to RowCount-1 do
    begin
      sOut := '';
      for iCol := 1 to ColCount-1 do
      begin
        if iCol > 0 then
        begin
          sOut := sOut + Cells[iCol,iRow];
        end;
      end;
      System.Writeln(fd_out,sOut);
    end;
  end;
  system.close(fd_out);
  Screen.Cursor := crDefault;
end;



procedure TfrmMain.btnLoadClick(Sender: TObject);
var
  fd_in      :System.Text;
  iRowSize   :Integer;
  iColSize   :Integer;
  iRC        :Integer;
  sDateiname :String;
  sIn        :String;
  sAll       :String;

begin
  OpenDialog1.InitialDir := '.\';
  OpenDialog1.Filter := 'TTL-Dateien (*.ttl)|*.ttl';

  if OpenDialog1.Execute then
  begin
    sDateiname := OpenDialog1.Filename;
    if (Pos('.',sDateiname) = 0) OR (Pos('.',ReverseString(sDateiname)) > 4 ) then
      sDateiname := sDateiname + '.ttl';
  end
  else
    exit;

  system.Assign(fd_in,sDateiname);

  iRowSize := 0;
  iColSize := 0;


  {$I-} System.Reset(fd_in); {$I-}
  iRC := IOResult;
  if iRC <> 0 then
  begin
    Application.MessageBox('Datei ist nicht vorhanden','Seltsam!',MB_OK);
    exit;
  end;

  Screen.Cursor := crHourglass;

  while not EOF(fd_in) do
  begin
    System.Readln(fd_in,sIn);
    if iRowSize = 0 then iRowSize := length(sIn);
    sAll := sAll + sIn;
    Inc(iColSize);
  end;

  if ( iRowSize <= 24 ) and  ( iColSize <= 24 ) and (iColSize*iRowSize = length(sAll)) then
  begin
    cboWidth.Text := IntToStr(iRowSize);
    cboHeight.Text :=  IntToStr(iColSize);
    cboSizeClick(cboHeight);
    putValStr(sAll,False);
  end
  else
  begin
     Application.MessageBox(PChar(Format('Mit der TTL-Datei stimmt etwas nicht! Zeilen:%d, Spalten:%d Zeichen:%d',[iColSize,iRowSize,length(sAll)])),'Seltsam!',MB_OK);
  end;
  
  Screen.Cursor := crDefault;
end;




procedure TfrmMain.btnBackClick(Sender: TObject);
var
  track :TActionTrack;
  iSP   :Integer;

begin
  if TrackIdx >= 0 then
  begin
    track := Tracker[TrackIdx];

    if track.Action = ACTPUSH then
    begin
      pop(False,True)
    end
    else if (track.Action = ACTPOPPT )  then
    begin
      push(True);
      putValStr(track.FVal,true);
    end
    else if ( track.Action = ACTPOPNP ) then
    begin
      iSP := Length(Stack);
      SetLength(Stack,iSP+1);
      Stack[iSP] := track.FVal;
    end
    else
       SetCell(track.Col,track.Row,track.FVal,true);
    Dec(TrackIdx);


    if track.Action = ACTPUSH then
       AddToLog(Format('%d: Rev(PUSH)  SP:%d',[TrackIdx+1,Length(Stack)-1]))
    else if track.Action = ACTPOPPT then
       AddToLog(Format('%d: Rev(POP[Put]) SP:%d',[TrackIdx+1,Length(Stack)-1]))
    else if track.Action = ACTPOPNP then
       AddToLog(Format('%d: Rev(POP[NOPut]) SP:%d',[TrackIdx+1,Length(Stack)-1]))
    else
       AddToLog(Format('%d: Rev(SET[%d,%d] from ''%s'' to ''%s'') ',[TrackIdx+1,track.Col,track.Row,track.FVal,track.TVal]));

    StringGrid1.Repaint;
  end;




end;

procedure TfrmMain.btnForwardClick(Sender: TObject);
var
  track :TActionTrack;

begin

  if TrackIdx < Length(Tracker)-1 then
  begin
    Inc(TrackIdx);
    track := Tracker[TrackIdx];

    if track.Action = ACTPUSH then
      push(True)
    else if track.Action = ACTPOPPT then
      pop(False,True)
    else if track.Action = ACTPOPNP then
      pop(True,True)
    else
      SetCell(track.Col,track.Row,track.TVal,true);

    if track.Action = ACTPUSH then
       AddToLog(Format('%d: PUSH  SP:%d',[TrackIdx,Length(Stack)-1]))
    else if track.Action = ACTPOPPT then
       AddToLog(Format('%d: POP (Put) SP:%d',[TrackIdx,Length(Stack)-1]))
    else if track.Action = ACTPOPNP then
       AddToLog(Format('%d: POP (NOPut) SP:%d',[TrackIdx,Length(Stack)-1]))
    else
       AddToLog(Format('%d: SET[%d,%d] from ''%s'' to ''%s'' ',[TrackIdx,track.Col,track.Row,track.FVal,track.TVal]));

    StringGrid1.Repaint;
  end;


end;



procedure TfrmMain.btnTrackerClick(Sender: TObject);
var
  i     :integer;
  track :TActionTrack;

begin

  for i:= 0 to Length(Tracker)-1 do
  begin
    track := Tracker[i];
    if track.Action = ACTPUSH then
       AddToLog(Format('%d: PUSH',[i]))
    else if track.Action = ACTPOPPT then
       AddToLog(Format('%d: POP (Put)',[i]))
    else if track.Action = ACTPOPNP then
       AddToLog(Format('%d: POP (NOPut)',[i]))
    else
       AddToLog(Format('%d: SET[%d,%d] from ''%s'' to ''%s'' ',[i,track.Col,track.Row,track.FVal,track.TVal]));
  end;

end;

end.
