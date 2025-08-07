unit CylinderEndpointsService;

interface

uses
  SysUtils, Matrix, Math;

function GetCylinderEndpoints(
  const ZIntercept, AxisDir: TDoubleMatrix;
  Length: Double
): TDoubleMatrix;

implementation

function GetCylinderEndpoints(
  const ZIntercept, AxisDir: TDoubleMatrix;
  Length: Double
): TDoubleMatrix;
var
  NormAxis: TDoubleMatrix;
  Mag: Double;
  i: Integer;
begin
  // Step 1: Normalize AxisDir
  NormAxis := TDoubleMatrix.Create(3, 1);
  Mag := Sqrt(Sqr(AxisDir[0, 0]) + Sqr(AxisDir[1, 0]) + Sqr(AxisDir[2, 0]));

  if Mag < 1e-8 then
    raise Exception.Create('Axis direction has near-zero magnitude.');

  for i := 0 to 2 do
    NormAxis[i, 0] := AxisDir[i, 0] / Mag;

  // Step 2: Initialize result matrix: 3×2 (Start and End points)
  Result := TDoubleMatrix.Create(3, 2);

  // Step 3: Compute endpoints along axis from ZIntercept
  for i := 0 to 2 do
  begin
    Result[i, 0] := ZIntercept[i, 0] - 0.5 * Length * NormAxis[i, 0];  // Start
    Result[i, 1] := ZIntercept[i, 0] + 0.5 * Length * NormAxis[i, 0];  // End
  end;

  NormAxis.Free;
end;


end.

