unit JDPMCylinderFitProject;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, sBitBtn,
  sMemo, sLabel,
  sEdit,
  Types,
  Matrix,
  MtxTimer,
  PCAUtils,
  ReadData_USA,
  PrintData,
  Math,
  CircleFitUtils,
  MatrixConst,
  OptimizationUtils,
  PseudoInverseUtils,
  PseudoFitUtils,
  DimensionsIteratorUtils,
  Generics.Collections,
  CylinderFitUtils;

var
  StartTime: Int64;
  EndTime: Int64;
  DeltaTime: Double;
  DeltaTimeStr: string;


type
  TForm_JDPMCylinderFit = class(TForm)
    sLabel_DefaultNotepadEditor: TsLabel;
    sMemo_PointcloudFilename: TsMemo;
    sBitBtn_OpenSelectDialog_DefaultNotepadFolder: TsBitBtn;
    sBitBtn1: TsBitBtn;
    sMemo1: TsMemo;
    FileOpenDialog_PointCloudFilename: TFileOpenDialog;
    procedure sBitBtn_OpenSelectDialog_DefaultNotepadFolderClick(
      Sender: TObject);
    procedure sBitBtn1Click(Sender: TObject);
  private
    { Private declarations }

    procedure JDPM_CalcCylinderCenterline;

  public
    { Public declarations }
  end;

var
  Form_JDPMCylinderFit: TForm_JDPMCylinderFit;

implementation

{$R *.dfm}


procedure TForm_JDPMCylinderFit.JDPM_CalcCylinderCenterline;
var
  Points: IMatrix;
  PCAResult: TPCAResult;
  ProjectedPoints: IMatrix;
  B, D: TDoubleMatrix;
  InitialGuess: IMatrix;
  OptCircleResult: TCircleResultOpt;
  i, j: Integer;
  ParamsPseudoInverse, OptimizedParams: IMatrix;
  param_a, param_b, param_c: Double;
  param_pp_a, param_pp_b, param_pp_c: Double;
  RadiusList, CenterXList, CenterYList: TList<Double>;
  SubProjectedPoints: IMatrix;
  dim_x, dim_y: Integer;
  FitResult: TCylinderFitResult;

  BestCenterX, BestCenterY, BestCenterZ, BestRadius: Double;
  MeasuredRadius: Double;
  EigenVectors: IMatrix;
  EigenValues: IMatrix;
  CylinderAxis: IMatrix;
  CircleCenter2D: TDoubleMatrix;

begin

  sMemo1.Lines.Clear;

  sMemo1.Lines.Add('Cylinder Centerline');
  sMemo1.Lines.Add('');

  // Step 1: Read the point cloud from the file
  //Points := ReadPointCloudFromFile('C:\Users\SKG Tecnología\Documents\AdvancedTubularTech-CylinderCenterline-2.0\Data\Point Cloud - 3 inch OD - Single Cylinder.txt');   // Juan Point Cloud.txt -- Juan Point Cloud - Sample 3.TXT
  //Points := ReadPointCloudFromFile('D:\Sync\File Transfer Share\Vendors\Juan David Prada Malagon\Cylinders\Point Cloud - 3 inch OD - Single Cylinder.TXT');   // Juan Point Cloud.txt -- Juan Point Cloud - Sample 3.TXT
  //Points := ReadPointCloudFromFile('D:\Sync\File Transfer Share\Vendors\Juan David Prada Malagon\Cylinders\Point Cloud - 0.25 inch OD - Single Cylinder.TXT');

  Points := ReadPointCloudFromFile(sMemo_PointcloudFilename.text, TMemo(sMemo1));

  if Points = nil then
  begin
    sMemo1.Lines.Add('Failed to load point cloud data.');
    Exit;
  end;

  if (Points.Height <> 3) and (Points.Width = 3) then
  begin
    sMemo1.Lines.Add('Transposing matrix to match PCA input format...');
    Points := Points.Transpose;
  end;

    // Start timer
  StartTime := MtxGetTime;

  try

    PCAResult := PerformPCA(Points, 1);

    EigenVectors := PCAResult.EigenVectors;
    EigenValues := PCAResult.EigenValues;

    //Writeln('CylinderAxis.Height', 'CylinderAxis.Width');
    //Writeln(EigenVectors.Height, EigenVectors.Width);

    //PrintMatrix(EigenVectors);
    //PrintMatrix(EigenValues);

    //Writeln('Principal Axis Vector (Centerline Direction): ');
    //for i := 0 to CylinderAxis.Height - 1 do
    //  Writeln(Format('  Axis[%d] = %f', [i, CylinderAxis[i, 0]]));


    try

      ProjectedPoints := ProjectToSelectedFeatureSpace(Points, PCAResult, 3);

      begin

        //MeasuredRadius := 12.5; // 12.5 -- 34
        //FitCircleForDimensionPairs(ProjectedPoints, MeasuredRadius, BestCenterX, BestCenterY, BestRadius);
        //Writeln(' ');
        // Writeln(Format('Centerline Direction = (%.4f, %.4f)',
        //             [EigenVectors[0, 0], EigenVectors[1, 0]]));
        //Writeln(Format('Centerline Direction = (X = %.4f, Y = %.4f, Z = %.4f)',
        //       [EigenVectors[0, 0], EigenVectors[1, 0], EigenVectors[2, 0]]));

        // NEW
        // Build a small matrix representing the 2D circle center
//        CircleCenter2D := TDoubleMatrix.Create(1, 2);
//        CircleCenter2D[0, 0] := BestCenterX;
//        CircleCenter2D[0, 1] := BestCenterY;

        // Compute the missing Z
//        BestCenterZ := ProjectCircleCenterToAxis(CircleCenter2D, PCAResult);
        // Writeln('BestCenterZ = %f', BestCenterZ);

//        CircleCenter2D.Free;

        MeasuredRadius := 1;

        FitResult := FitCylinderFromPointCloud(Points, MeasuredRadius, TMemo(sMemo1));

        sMemo1.Lines.Add('Fitted Cylinder:');
        sMemo1.Lines.Add(Format('  Axis Direction: (%.4f, %.4f, %.4f)',
         [FitResult.AxisDirection[0], FitResult.AxisDirection[1], FitResult.AxisDirection[2]]));
        //Writeln(Format('  Axis Point:     (%.4f, %.4f, %.4f)',
        // [FitResult.AxisPoint[0], FitResult.AxisPoint[1], FitResult.AxisPoint[2]]));
        sMemo1.Lines.Add(Format('  Radius:         %.4f', [FitResult.Radius]));

      end;

    finally

      ProjectedPoints := nil;
      Points := nil;   // Properly release the IMatrix reference

    end;

  except
    on E: Exception do
    begin
      sMemo1.Lines.Add('Error performing PCA: ' + E.Message);
      Exit;
    end;
  end;

    // End timer
  EndTime := MtxGetTime;

  // Calculate elapsed time
  DeltaTime := (EndTime - StartTime) / mtxFreq;
  DeltaTimeStr := FloatToStr(DeltaTime);

  // Display elapsed time
  sMemo1.Lines.Add('');
  sMemo1.Lines.Add('Elapsed Time = ' + DeltaTimeStr + ' s');

end;

procedure TForm_JDPMCylinderFit.sBitBtn1Click(Sender: TObject);
begin

  try
    JDPM_CalcCylinderCenterline;
  except
    on E: Exception do
      sMemo1.Lines.Add(E.ClassName + ': ' + E.Message);
  end;

end;

procedure TForm_JDPMCylinderFit.sBitBtn_OpenSelectDialog_DefaultNotepadFolderClick(
  Sender: TObject);
begin
  FileOpenDialog_PointCloudFilename.Defaultfolder :=
    'C:\Users\MichaelCone\wkspaces\repository_vtube2\_source\CylinderFitEngine\TestClouds\';
  if not FileOpenDialog_PointCloudFilename.execute then exit;
  sMemo_PointcloudFilename.Text := FileOpenDialog_PointCloudFilename.FileName;

end;

end.
