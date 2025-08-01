unit PCAMultiPlaneIterationService;

interface

uses
  Matrix;

type
  TPlaneScoreRecord = record
    DimX, DimY, DimZ: Integer;
    Projection2D: TDoubleMatrix;
    Center2D: TDoubleMatrix;
    Radius: Double;
    Residual: Double;
    RadiusMean: Double;
    RadiusStd: Double;
  end;

  TPlaneScoreArray = array of TPlaneScoreRecord;

function ScoreAllPCAPlanes(
  const Points, EigenVectors, MeanVector: TDoubleMatrix
): TPlaneScoreArray;

function SelectBestPlaneFromScores(
  const Scores: TPlaneScoreArray
): TPlaneScoreRecord;

function GetCylinderAxisFromBestPlane(const EigenVectors: TDoubleMatrix;
                                      const BestPlane: TPlaneScoreRecord): TDoubleMatrix;


implementation

uses
  SysUtils, Math, PCAProjectionService, CircleFitService;

function ComputeRadiusStats(
  const Points2D: TDoubleMatrix;
  CenterX, CenterY: Double;
  out MeanR, StdR: Double
): Boolean;
var
  i: Integer;
  dx, dy, r, sumR, sumSq, n: Double;
begin
  sumR := 0;
  sumSq := 0;
  n := Points2D.Width;

  for i := 0 to Points2D.Width - 1 do
  begin
    dx := Points2D[i, 0] - CenterX;
    dy := Points2D[i, 1] - CenterY;
    r := Sqrt(Sqr(dx) + Sqr(dy));

    sumR := sumR + r;
    sumSq := sumSq + r * r;
  end;

  MeanR := sumR / n;
  StdR := Sqrt((sumSq / n) - Sqr(MeanR));
  Result := True;
end;

function ScoreAllPCAPlanes(
  const Points, EigenVectors, MeanVector: TDoubleMatrix
): TPlaneScoreArray;
const
  DimPairs: array[0..2, 0..1] of Integer = ((0, 1), (0, 2), (1, 2));
var
  i: Integer;
  Proj: TDoubleMatrix;
  Fit: TCircleFitResult;
  RMean, RStd: Double;
begin

  //Writeln('ScoreAllPCAPlanes');
  SetLength(Result, 3);

  for i := 0 to 2 do
  begin

    //Writeln('i = ', i);

    Result[i].DimX := DimPairs[i][0];
    Result[i].DimY := DimPairs[i][1];
    Result[i].DimZ := 3 - Result[i].DimX - Result[i].DimY;


    Proj := ProjectToPlane(Points, EigenVectors, MeanVector, Result[i].DimX, Result[i].DimY);
    Result[i].Projection2D := Proj;

    Fit := FitCircle2D(Proj);

    //Writeln('Fit.Radius = ', Fit.Radius);
    //Writeln('Fit.Residual = ', Fit.Residual);

    Result[i].Center2D := TDoubleMatrix.Create(2, 1);
    Result[i].Center2D[0, 0] := Fit.Center2D[0, 0];
    Result[i].Center2D[1, 0] := Fit.Center2D[0, 1];

    Result[i].Radius := Fit.Radius;
    Result[i].Residual := Fit.Residual;

    ComputeRadiusStats(Proj, Fit.Center2D[0, 0], Fit.Center2D[0, 1], RMean, RStd);
    Result[i].RadiusMean := RMean;
    Result[i].RadiusStd := RStd;

    //Writeln('RadiusMean = ', RMean);
    //Writeln('RadiusStd = ', RStd);
  end;
end;


function SelectBestPlaneFromScores(
  const Scores: TPlaneScoreArray
): TPlaneScoreRecord;
var
  i: Integer;
  BestIndex: Integer;
  BestResidual, BestStd, BestRadiusDiff, RadiusDiff: Double;
begin
  if Length(Scores) = 0 then
    raise Exception.Create('No PCA plane scores provided.');

  BestIndex := -1;
  BestResidual := MaxDouble;
  BestStd := MaxDouble;
  BestRadiusDiff := MaxDouble;

  for i := 0 to High(Scores) do
  begin
    RadiusDiff := Abs(Scores[i].Radius - Scores[i].RadiusMean);

    if (Scores[i].Residual < BestResidual) and    //    Continous -Dense Condition
       (Scores[i].RadiusStd < BestStd) and
       (RadiusDiff < BestRadiusDiff)

       //(Scores[i].RadiusStd >= 3.5)      // Discrete Condition that worked for 25 points
       then
    begin
      BestResidual := Scores[i].Residual;
      BestStd := Scores[i].RadiusStd;
      BestRadiusDiff := RadiusDiff;
      BestIndex := i;
    end;
  end;

  if BestIndex = -1 then
    raise Exception.Create('No suitable PCA plane found.');

  Result := Scores[BestIndex];
end;


function GetCylinderAxisFromBestPlane(const EigenVectors: TDoubleMatrix;
                                      const BestPlane: TPlaneScoreRecord): TDoubleMatrix;
var
  i, AxisIndex: Integer;
  UsedDims: set of 0..2;
begin
  UsedDims := [BestPlane.DimX, BestPlane.DimY];

  // Find the dimension not used in the projection plane
  for i := 0 to 2 do
  begin
    if not (i in UsedDims) then
    begin
      AxisIndex := i;
      Break;
    end;
  end;

  // Extract eigenvector for the axis
  Result := TDoubleMatrix.Create(3, 1);
  Result[0, 0] := EigenVectors[AxisIndex, 0];
  Result[1, 0] := EigenVectors[AxisIndex, 1];
  Result[2, 0] := EigenVectors[AxisIndex, 2];
end;


end.

