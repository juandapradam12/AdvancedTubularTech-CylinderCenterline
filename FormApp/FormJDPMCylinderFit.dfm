object Form_JDPMCylinderFit: TForm_JDPMCylinderFit
  Left = 0
  Top = 0
  Caption = 'Cylinder Fit Test'
  ClientHeight = 570
  ClientWidth = 677
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object sLabel_DefaultNotepadEditor: TLabel
    Left = 44
    Top = 35
    Width = 103
    Height = 13
    Alignment = taRightJustify
    Caption = 'Point Cloud Filename:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 1184274
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object sMemo_PointcloudFilename: TMemo
    Left = 168
    Top = 35
    Width = 409
    Height = 89
    Lines.Strings = (
      
        'C:\Users\MichaelCone\wkspaces\repository_vtube2\_source\Cylinder' +
        'FitEngine'
      '\TestClouds\Point Cloud - 3 inch OD - Single Cylinder.TXT')
    TabOrder = 0
  end
  object sMemo1: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 209
    Width = 671
    Height = 358
    Align = alBottom
    TabOrder = 3
    ExplicitTop = 201
    ExplicitWidth = 669
  end
  object sBitBtn_OpenSelectDialog_DefaultNotepadFolder: TBitBtn
    Left = 586
    Top = 35
    Width = 48
    Height = 31
    Caption = '..'
    TabOrder = 1
    WordWrap = True
    OnClick = sBitBtn_OpenSelectDialog_DefaultNotepadFolderClick
  end
  object sBitBtn1: TBitBtn
    Left = 168
    Top = 130
    Width = 409
    Height = 55
    Caption = 'Load Point Clouds and Calculate Cylinder Fit'
    TabOrder = 2
    WordWrap = True
    OnClick = sBitBtn1Click
  end
  object FileOpenDialog_PointCloudFilename: TFileOpenDialog
    DefaultExtension = 'TXT'
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'Text File'
        FileMask = '*.txt'
      end>
    Options = []
    Left = 284
    Top = 256
  end
end
