object Form4: TForm4
  Left = 0
  Top = 0
  Caption = #20010#20154#20351#29992#21151#33021#25110#20989#25968#20363#23376
  ClientHeight = 498
  ClientWidth = 733
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pgc1: TPageControl
    Left = 0
    Top = 0
    Width = 733
    Height = 498
    ActivePage = ts1
    Align = alClient
    TabOrder = 0
    object ts1: TTabSheet
      Caption = 'ts1'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object pnl1: TPanel
        Left = 0
        Top = 168
        Width = 725
        Height = 302
        Align = alBottom
        Caption = 'pnl1'
        TabOrder = 0
        object mmo1: TMemo
          Left = 1
          Top = 1
          Width = 723
          Height = 300
          Align = alClient
          Lines.Strings = (
            '')
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
      object btn1: TButton
        Left = 8
        Top = 38
        Width = 75
        Height = 25
        Caption = #22495#21517#35299#26512
        TabOrder = 1
        OnClick = btn1Click
      end
      object edt1: TEdit
        Left = 8
        Top = 6
        Width = 697
        Height = 21
        TabOrder = 2
        Text = 'edt1'
      end
      object btn2: TButton
        Left = 104
        Top = 38
        Width = 75
        Height = 25
        Caption = 'ADB '#21629#20196
        TabOrder = 3
        OnClick = btn2Click
      end
      object btnSpeexDecode: TButton
        Left = 196
        Top = 38
        Width = 75
        Height = 25
        Caption = 'Speex Decode'
        TabOrder = 4
        OnClick = btnSpeexDecodeClick
      end
      object btn3: TButton
        Left = 296
        Top = 38
        Width = 75
        Height = 25
        Caption = 'Play Sound'
        TabOrder = 5
        OnClick = btn3Click
      end
    end
    object ts2: TTabSheet
      Caption = 'ts2'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
  end
end
