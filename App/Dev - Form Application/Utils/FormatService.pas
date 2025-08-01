unit FormatService;

interface

uses
  Matrix, SysUtils;

function ConvertToTDoubleMatrix(const AMatrix: IMatrix): TDoubleMatrix;
function ConvertToIMatrix(const AMatrix: TDoubleMatrix): IMatrix;

implementation

function ConvertToTDoubleMatrix(const AMatrix: IMatrix): TDoubleMatrix;
var
  Row, Col: Integer;
begin
  // Create a new TDoubleMatrix instance with the same dimensions as the input matrix
  Result := TDoubleMatrix.Create(AMatrix.Width, AMatrix.Height);
  try
    // Copy each element from the IMatrix to the TDoubleMatrix
    for Row := 0 to AMatrix.Width - 1 do
    begin
      for Col := 0 to AMatrix.Height - 1 do
      begin
        Result[Row, Col] := AMatrix[Row, Col];
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function ConvertToIMatrix(const AMatrix: TDoubleMatrix): IMatrix;
begin
  // Return the TDoubleMatrix as an IMatrix
  // This works since TDoubleMatrix implements IMatrix
  Result := AMatrix;
end;

end.

