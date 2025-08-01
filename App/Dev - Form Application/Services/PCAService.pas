unit PCAService;

interface

uses
  Matrix;

type
  TPCAResult = record
    EigenVectors: TDoubleMatrix;  // 3×3 matrix
    EigenValues: TDoubleMatrix;   // 1×3 matrix
    MeanVector: TDoubleMatrix;    // 3×1 mean
  end;

function PerformPCA(const Points: TDoubleMatrix; VarianceRetained: Double = 1.0): TPCAResult;

implementation

uses
  PCA, SysUtils;

function PerformPCA(const Points: TDoubleMatrix; VarianceRetained: Double): TPCAResult;
var
  PCA: TMatrixPCA;
begin
  PCA := TMatrixPCA.Create([pcaEigVals, pcaMeanNormalizedData, pcaTransposedEigVec]);

  try
    if not PCA.PCA(Points, VarianceRetained, True) then
      raise Exception.Create('PCA computation failed.');

    SortEigValsEigVecs(PCA.EigVals, PCA.EigVecs, 0, PCA.EigVals.Height - 1);

    Result.EigenVectors := PCA.EigVecs.Clone;
    Result.EigenValues := PCA.EigVals.Clone;
    Result.MeanVector := PCA.Mean.Clone;
  finally
    PCA.Free;
  end;
end;

end.

