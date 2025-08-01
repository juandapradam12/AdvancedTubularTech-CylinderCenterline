unit PCAProjectionService;

interface

uses
  SysUtils, Matrix;

type
  TVec3 = array[0..2] of Double;

function ProjectToPlane(const Points, EigenVectors, MeanVector: TDoubleMatrix;
  DimX, DimY: Integer): TDoubleMatrix;

implementation

function ProjectToPlane(const Points, EigenVectors, MeanVector: TDoubleMatrix;
  DimX, DimY: Integer): TDoubleMatrix;
var
  i: Integer;
  U, W: TVec3;
  Centered: TVec3;
  ResultMatrix: TDoubleMatrix;
begin
  if (Points.Height <> 3) or (EigenVectors.Height <> 3) or (EigenVectors.Width <> 3) then
    raise Exception.Create('Expecting 3D point cloud and 3x3 PCA matrix.');

  // Extract PCA vectors to span the plane
  U[0] := EigenVectors[DimX, 0];
  U[1] := EigenVectors[DimX, 1];
  U[2] := EigenVectors[DimX, 2];

  W[0] := EigenVectors[DimY, 0];
  W[1] := EigenVectors[DimY, 1];
  W[2] := EigenVectors[DimY, 2];

  // Create 2D projection matrix (Points.Width x 2)
  ResultMatrix := TDoubleMatrix.Create(Points.Width, 2);

  for i := 0 to Points.Width - 1 do
  begin
    Centered[0] := Points[i, 0] - MeanVector[0, 0];
    Centered[1] := Points[i, 1] - MeanVector[0, 1];
    Centered[2] := Points[i, 2] - MeanVector[0, 2];

    ResultMatrix[i, 0] := Centered[0] * U[0] + Centered[1] * U[1] + Centered[2] * U[2];
    ResultMatrix[i, 1] := Centered[0] * W[0] + Centered[1] * W[1] + Centered[2] * W[2];
  end;

  //Writeln(Format('ResultMatrix Size: %d rows × %d columns', [ResultMatrix.Height, ResultMatrix.Width]));

  Result := ResultMatrix;
end;

end.


