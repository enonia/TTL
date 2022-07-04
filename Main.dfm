object frmMain: TfrmMain
  Left = 1223
  Top = 224
  Width = 582
  Height = 823
  Caption = 'TTL'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Panel2: TPanel
    Left = 97
    Top = 0
    Width = 469
    Height = 760
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object StringGrid1: TStringGrid
      Left = 1
      Top = 0
      Width = 153
      Height = 153
      Cursor = crHandPoint
      ColCount = 8
      Ctl3D = False
      DefaultColWidth = 18
      DefaultRowHeight = 18
      DefaultDrawing = False
      FixedCols = 0
      RowCount = 8
      FixedRows = 0
      Font.Charset = SYMBOL_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Wingdings'
      Font.Style = [fsBold]
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine]
      ParentCtl3D = False
      ParentFont = False
      ScrollBars = ssNone
      TabOrder = 0
      OnDrawCell = StringGrid1DrawCell
      OnMouseDown = StringGrid1MouseDown
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 97
    Height = 760
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object Size: TLabel
      Left = 7
      Top = 12
      Width = 28
      Height = 13
      Caption = 'Width'
    end
    object Label1: TLabel
      Left = 2
      Top = 35
      Width = 31
      Height = 13
      Caption = 'Height'
    end
    object cboWidth: TComboBox
      Left = 40
      Top = 8
      Width = 49
      Height = 21
      ItemHeight = 13
      TabOrder = 0
      Text = '6'
      OnClick = cboSizeClick
      Items.Strings = (
        '2'
        '4'
        '6'
        '8'
        '10'
        '12'
        '14'
        '16'
        '18'
        '20'
        '22'
        '24')
    end
    object cboHeight: TComboBox
      Left = 40
      Top = 32
      Width = 49
      Height = 21
      ItemHeight = 13
      TabOrder = 1
      Text = '6'
      OnClick = cboSizeClick
      Items.Strings = (
        '2'
        '4'
        '6'
        '8'
        '10'
        '12'
        '14'
        '16'
        '18'
        '20'
        '22'
        '24')
    end
    object btnClear: TButton
      Left = 16
      Top = 72
      Width = 49
      Height = 20
      Caption = 'clear'
      TabOrder = 2
      OnClick = btnClearClick
    end
    object btnPush: TButton
      Left = 16
      Top = 96
      Width = 49
      Height = 20
      Caption = 'push'
      TabOrder = 3
      OnClick = btnPushClick
    end
    object btnPop: TButton
      Left = 16
      Top = 120
      Width = 49
      Height = 20
      Caption = 'pop'
      TabOrder = 4
      OnClick = btnPopClick
    end
    object btnSolve: TButton
      Left = 16
      Top = 144
      Width = 49
      Height = 20
      Caption = 'solve'
      TabOrder = 5
      OnClick = btnSolveClick
    end
    object chkLog: TCheckBox
      Left = 8
      Top = 256
      Width = 41
      Height = 17
      Caption = 'Log'
      TabOrder = 6
      OnClick = chkLogClick
    end
    object chkHint: TCheckBox
      Left = 8
      Top = 272
      Width = 97
      Height = 17
      Caption = 'Hint'
      TabOrder = 7
      OnClick = chkHintClick
    end
    object Panel4: TPanel
      Left = 8
      Top = 424
      Width = 73
      Height = 41
      Color = 13284266
      TabOrder = 8
      Visible = False
    end
    object chkSlow: TCheckBox
      Left = 8
      Top = 288
      Width = 97
      Height = 17
      Caption = 'Slow'
      TabOrder = 9
    end
    object btnLoad: TButton
      Left = 16
      Top = 168
      Width = 49
      Height = 20
      Caption = 'load'
      TabOrder = 10
      OnClick = btnLoadClick
    end
    object btnSave: TButton
      Left = 16
      Top = 192
      Width = 49
      Height = 20
      Caption = 'save'
      TabOrder = 11
      OnClick = btnSaveClick
    end
    object cbBacktracking: TCheckBox
      Left = 8
      Top = 240
      Width = 97
      Height = 17
      Caption = 'Backtracking'
      Checked = True
      State = cbChecked
      TabOrder = 12
    end
    object btnBack: TButton
      Left = 8
      Top = 312
      Width = 25
      Height = 20
      Caption = '<'
      TabOrder = 13
      OnClick = btnBackClick
    end
    object btnForward: TButton
      Left = 40
      Top = 312
      Width = 25
      Height = 20
      Caption = '>'
      TabOrder = 14
      OnClick = btnForwardClick
    end
    object btnTracker: TButton
      Left = 8
      Top = 344
      Width = 49
      Height = 20
      Caption = 'tracker'
      TabOrder = 15
      OnClick = btnTrackerClick
    end
  end
  object pnlMsg: TPanel
    Left = 0
    Top = 760
    Width = 566
    Height = 24
    Align = alBottom
    BevelOuter = bvNone
    BorderStyle = bsSingle
    TabOrder = 2
    object lblCheck: TLabel
      Left = 16
      Top = 105
      Width = 3
      Height = 13
    end
  end
  object SaveDialog1: TSaveDialog
    Left = 305
    Top = 16
  end
  object OpenDialog1: TOpenDialog
    Left = 281
    Top = 16
  end
end
