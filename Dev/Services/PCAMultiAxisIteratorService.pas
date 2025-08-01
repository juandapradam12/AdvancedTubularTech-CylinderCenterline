unit PCAMultiAxisIteratorService;

interface

uses
  SysUtils, Matrix, StripeDetectionService;

type
  TAxisStripeInfo = record
    AxisIndex: Integer;
    AxisDirection: TDoubleMatrix;  // 3×1 vector
    StripeResult: TStripeResult;   // stripes & labels detected
  end;

  TAxisStripeInfoArray = array of TAxisStripeInfo;

function IterateOverPCAAxes(const Points, EigenVectors: TDoubleMatrix): TAxisStripeInfoArray;

implementation

function GetAxisDirection(const EigenVectors: TDoubleMatrix; AxisIndex: Integer): TDoubleMatrix;
begin
  // Extract the PCA component row and return as a 3×1 column vector
  if (EigenVectors.Height <> 3) or (EigenVectors.Width <> 3) then
    raise Exception.Create('GetAxisDirection: EigenVectors must be 3×3.');
  Result := TDoubleMatrix.Create(3, 1);
  Result[0, 0] := EigenVectors[AxisIndex, 0];
  Result[1, 0] := EigenVectors[AxisIndex, 1];
  Result[2, 0] := EigenVectors[AxisIndex, 2];
end;

function IterateOverPCAAxes(const Points, EigenVectors: TDoubleMatrix): TAxisStripeInfoArray;
var
  i: Integer;
  AxisDir: TDoubleMatrix;
begin
  // Validate
  if Points.Height <> 3 then
    raise Exception.Create('IterateOverPCAAxes: Points must be 3×N.');
  if (EigenVectors.Height <> 3) or (EigenVectors.Width <> 3) then
    raise Exception.Create('IterateOverPCAAxes: EigenVectors must be 3×3.');

  SetLength(Result, 3);

  for i := 0 to 2 do
  begin
    AxisDir := GetAxisDirection(EigenVectors, i);
    Result[i].AxisIndex := i;
    Result[i].AxisDirection := AxisDir;
    Result[i].StripeResult := DetectStripesAlongAxis(Points, AxisDir, 3.0);

    Writeln(Format('Axis %d: found %d stripes.', [i, Length(Result[i].StripeResult.Stripes)]));
  end;
end;

end.


