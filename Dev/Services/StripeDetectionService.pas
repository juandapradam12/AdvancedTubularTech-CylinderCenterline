unit StripeDetectionService;

interface

uses
  SysUtils, Math, Matrix;

type
  TIntegerArray = array of Integer;

  TStripeResult = record
    Labels: TIntegerArray;             // stripe index for each point
    Stripes: array of TDoubleMatrix;   // each stripe as 3×M matrix
  end;

function DetectStripesAlongAxis(
  const Points, AxisDir: TDoubleMatrix;
  GapFactor: Double = 3.0
): TStripeResult;

implementation

type
  TSortableProj = record
    Value: Double;
    Index: Integer;
  end;
  TSortableProjArray = array of TSortableProj;

procedure QuickSort(var A: TSortableProjArray; L, R: Integer);
var
  I, J: Integer;
  Pivot, Temp: TSortableProj;
begin
  I := L;
  J := R;
  Pivot := A[(L + R) div 2];
  repeat
    while A[I].Value < Pivot.Value do Inc(I);
    while A[J].Value > Pivot.Value do Dec(J);
    if I <= J then
    begin
      Temp := A[I];
      A[I] := A[J];
      A[J] := Temp;
      Inc(I);
      Dec(J);
    end;
  until I > J;
  if L < J then QuickSort(A, L, J);
  if I < R then QuickSort(A, I, R);
end;

function DetectStripesAlongAxis(
  const Points, AxisDir: TDoubleMatrix;
  GapFactor: Double
): TStripeResult;
var
  N, i, k: Integer;
  AxisVec: array[0..2] of Double;
  Proj: TSortableProjArray;
  SortedVals: array of Double;
  SortedIdx: array of Integer;
  Diffs: array of Double;
  MeanGap, StdGap, GapThresh: Double;
  Labels: TIntegerArray;
  StripeCounts: array of Integer;
  PosCount: array of Integer;
  StripeIdx: Integer;
  LenAxis: Double;
begin
  if Points.Height <> 3 then
    raise Exception.Create('DetectStripesAlongAxis: Points must be 3×N.');

  N := Points.Width;
  if N = 0 then
    raise Exception.Create('DetectStripesAlongAxis: Empty point cloud.');

  // normalize axis vector
  AxisVec[0] := AxisDir[0, 0];
  AxisVec[1] := AxisDir[1, 0];
  AxisVec[2] := AxisDir[2, 0];
  LenAxis := Sqrt(Sqr(AxisVec[0]) + Sqr(AxisVec[1]) + Sqr(AxisVec[2]));
  if LenAxis < 1e-12 then
    raise Exception.Create('DetectStripesAlongAxis: AxisDir has zero length.');
  AxisVec[0] := AxisVec[0] / LenAxis;
  AxisVec[1] := AxisVec[1] / LenAxis;
  AxisVec[2] := AxisVec[2] / LenAxis;

  // project all points onto axis
  SetLength(Proj, N);
  for i := 0 to N - 1 do
  begin
    Proj[i].Value := Points[i, 0] * AxisVec[0] +
                     Points[i, 1] * AxisVec[1] +
                     Points[i, 2] * AxisVec[2];
    Proj[i].Index := i;
  end;

  // sort by projection value
  QuickSort(Proj, 0, N - 1);
  SetLength(SortedVals, N);
  SetLength(SortedIdx, N);
  for i := 0 to N - 1 do
  begin
    SortedVals[i] := Proj[i].Value;
    SortedIdx[i] := Proj[i].Index;
  end;

  // compute diffs
  SetLength(Diffs, N - 1);
  for i := 0 to N - 2 do
    Diffs[i] := SortedVals[i + 1] - SortedVals[i];

  // mean gap
  MeanGap := 0;
  for i := 0 to High(Diffs) do
    MeanGap := MeanGap + Diffs[i];
  if Length(Diffs) > 0 then
    MeanGap := MeanGap / Length(Diffs);

  // std gap
  StdGap := 0;
  for i := 0 to High(Diffs) do
    StdGap := StdGap + Sqr(Diffs[i] - MeanGap);
  if Length(Diffs) > 1 then
    StdGap := Sqrt(StdGap / (Length(Diffs) - 1))
  else
    StdGap := 0;

  GapThresh := MeanGap + GapFactor * StdGap;

  // assign labels
  SetLength(Labels, N);
  StripeIdx := 0;
  Labels[SortedIdx[0]] := StripeIdx;
  for i := 0 to High(Diffs) do
  begin
    if Diffs[i] > GapThresh then
      Inc(StripeIdx);
    Labels[SortedIdx[i + 1]] := StripeIdx;
  end;

  // count how many stripes
  SetLength(StripeCounts, StripeIdx + 1);
  for i := 0 to N - 1 do
    Inc(StripeCounts[Labels[i]]);

  // create stripe matrices
  SetLength(Result.Stripes, StripeIdx + 1);
  for k := 0 to High(StripeCounts) do
    Result.Stripes[k] := TDoubleMatrix.Create(3, StripeCounts[k]);

  SetLength(PosCount, StripeIdx + 1);

  // fill stripe matrices
  for i := 0 to N - 1 do
  begin
    k := Labels[i];
    Result.Stripes[k][0, PosCount[k]] := Points[i, 0];
    Result.Stripes[k][1, PosCount[k]] := Points[i, 1];
    Result.Stripes[k][2, PosCount[k]] := Points[i, 2];
    Inc(PosCount[k]);
  end;

  // set labels
  Result.Labels := Labels;
end;

end.

