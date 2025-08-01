unit SmartInterceptService;

interface

uses
  Matrix;

function ComputeSmartIntercept(
  const LiftedCenter, AxisDirection: TDoubleMatrix
): TDoubleMatrix;

implementation

uses
  SysUtils, Math, ZInterceptService;

function VectorNorm(const V: TDoubleMatrix): Double;
begin
  Result := Sqrt(Sqr(V[0, 0]) + Sqr(V[1, 0]) + Sqr(V[2, 0]));
end;

function IsAxisParallelToZ(const AxisDir: TDoubleMatrix; Tolerance: Double = 0.01): Boolean;
var
  DotProd, Norm, CosAngle: Double;
begin
  Norm := VectorNorm(AxisDir);
  if Norm = 0 then
    raise Exception.Create('Zero-length axis vector');

  DotProd := AxisDir[2, 0];  // dot product with unit Z
  CosAngle := Abs(DotProd / Norm);  // = cos(theta)

  Writeln('CosAngle = ', CosAngle);

  Result := Abs(CosAngle - 1.0) < Tolerance;
end;

function ComputeSmartIntercept(
  const LiftedCenter, AxisDirection: TDoubleMatrix
): TDoubleMatrix;
var
  t, vy: Double;
begin
  Result := ComputeIntercept(LiftedCenter, AxisDirection);
end;

end.




