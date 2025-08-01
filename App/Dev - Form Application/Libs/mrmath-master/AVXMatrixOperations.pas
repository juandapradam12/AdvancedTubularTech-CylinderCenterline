// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2017, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################

unit AVXMatrixOperations;

// #################################################
// #### distributes the function to the assembler versions
// #################################################

interface

uses MatrixConst;

procedure AVXMatrixCopy(Dest : PDouble; destLineWidth : NativeInt; src : PDouble; srcLineWidth : NativeInt; Width, Height : NativeInt);
procedure AVXRowSwap(A, B : PDouble; width : NativeInt);
procedure AVXMatrixInit( dest : PDouble; destLineWidth : NativeInt; Width, Height : NativeInt; const value : double );

// note: The ASM routines always carry out 2x2 matrix multiplications thus there must be an additional zero line/column in the
// input matrices if the width/height is uneven. The routine also performs better if the matrices are aligned to 16 byte boundaries!
procedure AVXMatrixMult(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); overload;
procedure AVXMatrixMult(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt; mem : PDouble); overload;
procedure AVXMatrixMultTransposed(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); overload;
procedure AVXMatrixMultDirect(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); overload;

procedure AVXMtxVecMult(dest : PDouble; destLineWidth : NativeInt; mt1, v : PDouble; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : double);
procedure AVXMtxVecMultT(dest : PDouble; destLineWidth : NativeInt; mt1, v : PDouble; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : double);

procedure AVXRank1Update(A : PDouble; const LineWidthA : NativeInt; width, height : NativeInt;
  X, Y : PDouble; incX, incY : NativeInt; alpha : double);
procedure AVXSymRank2UpdateUpper( C : PDouble; LineWidthC : NativeInt; A : PDouble; LineWidthA : NativeInt;
  B : PDouble; LineWidthB : NativeInt; N : NativeInt; k : NativeInt );


function AVXMatrixVecDotMult( x : PDouble; incX : NativeInt; y : PDouble; incY : NativeInt; N : NativeInt ) : double;


// note: the matrix add routine tries to add two values at once and does not carry out any range checks thus the line widhts must
// be multiple of 16.
procedure AVXMatrixAdd(dest : PDouble; destLineWidth : NativeInt; mt1, mt2 : PDouble; width : NativeInt; height : NativeInt; LineWidth1, LineWidth2 : NativeInt);
procedure AVXMatrixAddVec(A : PDouble; LineWidthA : NativeInt; B : PDouble; incX : NativeInt; width, Height : NativeInt; rowWise : Boolean);

procedure AVXMatrixSub(dest : PDouble; destLineWidth : NativeInt; mt1, mt2 : PDouble; width : NativeInt; height : NativeInt; LineWidth1, LineWidth2 : NativeInt);
procedure AVXMatrixSubVec(A : PDouble; LineWidthA : NativeInt; B : PDouble; incX : NativeInt; width, Height : NativeInt; rowWise : Boolean);

procedure AVXMatrixElemMult(dest : PDouble; destLineWidth : NativeInt; mt1, mt2 : PDouble; width : NativeInt; height : NativeInt; LineWidth1, LineWidth2 : NativeInt);
procedure AVXMatrixElemDiv(dest : PDouble; destLineWidth : NativeInt; mt1, mt2 : PDouble; width : NativeInt; height : NativeInt; LineWidth1, LineWidth2 : NativeInt);
procedure AVXMatrixAddAndScale(Dest : PDouble;  LineWidth, Width, Height : NativeInt; const dOffset, Scale : double);
procedure AVXMatrixElemAdd(Dest : PDouble;  LineWidth, Width, Height : NativeInt; const dOffset : double);
procedure AVXMatrixScaleAndAdd(Dest : PDouble; LineWidth, Width, Height : NativeInt; const dOffset, Scale : double);
procedure AVXMatrixSQRT(Dest : PDouble; LineWidth : NativeInt; Width, Height : NativeInt);
procedure AVXMatrixAbs(Dest : PDouble; LineWidth : NativeInt; Width, Height : NativeInt);

function AVXMatrixMax(mt : PDouble; width, height : NativeInt; const LineWidth : NativeInt) : double; overload;
function AVXMatrixMin(mt : PDouble; width, height : NativeInt; const LineWidth : NativeInt) : double; overload;
procedure AVXMatrixMin(dest : PDouble; const LineWidth : NativeInt; width, height : NativeInt; minVal : double); overload;
procedure AVXMatrixMax(dest : PDouble; const LineWidth : NativeInt; width, height : NativeInt; maxVal : double); overload;
function AVXMatrixSumSum(src : PDouble; srcLineWidth : NativeInt; Width, Height : NativeInt): double;

procedure AVXMatrixTranspose(dest : PDouble; const destLineWidth : NativeInt; mt : PDouble; const LineWidth : NativeInt; width : NativeInt; height : NativeInt);
function AVXMatrixElementwiseNorm2(dest : PDouble; LineWidth : NativeInt; Width, height : NativeInt; doSqrt : boolean) : double;
procedure AVXMatrixNormalize(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);
procedure AVXMatrixMean(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);
procedure AVXMatrixVar(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean; unbiased : boolean);
procedure AVXMatrixMeanVar(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean; unbiased : boolean);
procedure AVXMatrixSum(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean); overload;
procedure AVXMatrixCumulativeSum(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);
procedure AVXMatrixDifferentiate(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);


// strassen algorithm for matrix multiplication
procedure AVXStrassenMatrixMultiplication(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt);

implementation

{$I 'mrMath_CPU.inc'}

{$IFDEF FPC} {$S-} {$ENDIF}

uses Math, 
     {$IFDEF x64}
     AVXMatrixMultTransposedOperationsx64, AVXMoveOperationsx64, AVXMatrixAbsOperationsx64,
     AVXMatrixScaleOperationsx64, AVXMatrixTransposeOperationsx64, AVXMatrixVectorMultOperationsx64,
     AVXMatrixAddSubOperationsx64, AVXMatrixMultOperationsx64, AVXMatrixCumSumDiffOperationsx64,
     AVXMatrixElementwiseMultOperationsx64, AVXMatrixMinMaxOperationsx64, AVXMatrixMeanOperationsx64,
     AVXMatrixNormOperationsx64, AVXMatrixSqrtOperationsx64, AVXMatrixSumOperationsx64, MatrixASMStubSwitch,
     {$ELSE}
     AVXMatrixMultOperations, AVXMatrixVectorMultOperations, AVXMatrixAbsOperations,
     AVXMatrixMultTransposedOperations, AVXMatrixAddSubOperations, AVXMatrixMeanOperations,
     AVXMatrixElementwiseMultOperations, AVXMatrixScaleOperations, AVXMatrixSQRTOperations,
     AVXMoveOperations, AVXMatrixMinMaxOperations, AVXMatrixTransposeOperations,
     AVXMatrixNormOperations, AVXMatrixSumOperations,
     AVXMatrixCumSumDiffOperations, MatrixASMStubSwitch,
     {$ENDIF}
     ASMMatrixOperations, SimpleMatrixOperations;


procedure AVXMatrixAddAndScale(Dest : PDouble; LineWidth, Width, Height : NativeInt; const dOffset, Scale : double);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (width = 1) and (LineWidth = sizeof(double)) then
     begin
          width := height;
          height := 1;
          LineWidth := width*sizeof(double);
          LineWidth := LineWidth + 32 - LineWidth and $1F;
     end;

     if (NativeUint(dest) and $0000001F = 0) and (LineWidth and $0000001F = 0) then
     begin
          if (width and 1) = 0
          then
              AVXMatrixAddScaleAlignedEvenW(dest, LineWidth, width, height, dOffset, Scale)
          else
              AVXMatrixAddScaleAlignedOddW(dest, LineWidth, width, height, dOffset, Scale);
     end
     else
     begin
          if (width and 1) = 0
          then
              AVXMatrixAddScaleUnAlignedEvenW(dest, LineWidth, width, height, dOffset, Scale)
          else
              AVXMatrixAddScaleUnAlignedOddW(dest, LineWidth, width, height, dOffset, Scale);
     end;
end;

procedure AVXMatrixElemAdd(Dest : PDouble;  LineWidth, Width, Height : NativeInt; const dOffset : double);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (width = 1) and (LineWidth = sizeof(double)) then
     begin
          width := height;
          height := 1;
          LineWidth := width*sizeof(double);
          LineWidth := LineWidth + 32 - LineWidth and $1F;
     end;

     if (NativeUint(dest) and $0000001F = 0) and (LineWidth and $0000001F = 0) then
     begin
          if (width and 1) = 0
          then
              AVXMatrixAddAlignedEvenW(dest, LineWidth, width, height, dOffset)
          else
              AVXMatrixAddAlignedOddW(dest, LineWidth, width, height, dOffset);
     end
     else
     begin
          if (width and 1) = 0
          then
              AVXMatrixAddUnAlignedEvenW(dest, LineWidth, width, height, dOffset)
          else
              AVXMatrixAddUnAlignedOddW(dest, LineWidth, width, height, dOffset);
     end;
end;


procedure AVXMatrixScaleAndAdd(Dest : PDouble; LineWidth, Width, Height : NativeInt; const dOffset, Scale : double);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (width = 1) and (LineWidth = sizeof(double)) then
     begin
          width := height;
          height := 1;
          LineWidth := width*sizeof(double);
          LineWidth := LineWidth + $20 - LineWidth and $1F;
     end;

     if (NativeUint(dest) and $0000001F = 0) and (LineWidth and $0000001F = 0) then
     begin
          if (width and 1) = 0
          then
              AVXMatrixScaleAddAlignedEvenW(dest, LineWidth, width, height, dOffset, Scale)
          else
              AVXMatrixScaleAddAlignedOddW(dest, LineWidth, width, height, dOffset, Scale);
     end
     else
     begin
          if (width and 1) = 0
          then
              AVXMatrixScaleAddUnAlignedEvenW(dest, LineWidth, width, height, dOffset, Scale)
          else
              AVXMatrixScaleAddUnAlignedOddW(dest, LineWidth, width, height, dOffset, Scale);
     end;
end;

procedure AVXMatrixSQRT(Dest : PDouble; LineWidth : NativeInt; Width, Height : NativeInt);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (width = 1) and (LineWidth = sizeof(double)) then
     begin
          width := height;
          height := 1;
          LineWidth := width*sizeof(double);
          LineWidth := LineWidth + 32 - LineWidth and $1F;
     end;

     if (NativeUint(dest) and $0000001F = 0) and (LineWidth and $0000001F = 0)
     then
         AVXMatrixSQRTAligned(dest, LineWidth, width, height)
     else
         AVXMatrixSQRTUnAligned(dest, LineWidth, width, height);
end;

procedure AVXMatrixAbs(Dest : PDouble; LineWidth : NativeInt; Width, Height : NativeInt);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (width = 1) and (LineWidth = sizeof(double)) then
     begin
          width := height;
          height := 1;
          LineWidth := width*sizeof(double);
          LineWidth := LineWidth + 32 - LineWidth and $1F;
     end;

     if (NativeUint(dest) and $0000001F = 0) and (LineWidth and $0000001F = 0)
     then
         AVXMatrixAbsAligned(dest, LineWidth, width, height)
     else
         AVXMatrixAbsUnAligned(dest, LineWidth, width, height);
end;

procedure AVXMatrixElemMult(dest : PDouble; destLineWidth : NativeInt; mt1, mt2 : PDouble; width : NativeInt; height : NativeInt; LineWidth1, LineWidth2 : NativeInt);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (width = 1) and (LineWidth1 = sizeof(double)) and (LineWidth2 = sizeof(double)) and (destLineWidth = sizeof(double)) then
     begin
          width := Height;
          height := 1;
          LineWidth1 := width*sizeof(double);
          LineWidth1 := LineWidth1 + 32 - LineWidth1 and $1F;
          LineWidth2 := LineWidth1;
          destLineWidth := LineWidth1;
     end;

     if (NativeUint(mt1) and $00000001F = 0) and (NativeUint(mt2) and $00000001F = 0) and (NativeUint(dest) and $00000001F = 0) and
        (destLineWidth and $00000001F = 0) and (LineWidth1 and $00000001F = 0) and (LineWidth2 and $00000001F = 0)
     then
         AVXMatrixElemMultAligned(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2)
     else
         AVXMatrixElemMultUnAligned(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2);
end;

procedure AVXMatrixElemDiv(dest : PDouble; destLineWidth : NativeInt; mt1, mt2 : PDouble; width : NativeInt; height : NativeInt; LineWidth1, LineWidth2 : NativeInt);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (width = 1) and (LineWidth1 = sizeof(double)) and (LineWidth2 = sizeof(double)) and (destLineWidth = sizeof(double)) then
     begin
          width := Height;
          height := 1;
          LineWidth1 := width*sizeof(double);
          LineWidth1 := LineWidth1 + 32 - LineWidth1 and $1F;
          LineWidth2 := LineWidth1;
          destLineWidth := LineWidth1;
     end;

     if (NativeUint(mt1) and $0000001F = 0) and (NativeUint(mt2) and $0000001F = 0) and (NativeUint(dest) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (LineWidth1 and $0000001F = 0) and (LineWidth2 and $0000001F = 0)
     then
         AVXMatrixElemDivAligned(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2)
     else
         AVXMatrixElemDivUnAligned(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2);
end;

function AVXMatrixElementwiseNorm2(dest : PDouble; LineWidth : NativeInt; Width, height : NativeInt; doSqrt : boolean) : double;
begin
     Result := 0;

     if (width = 0) or (height = 0) then
        exit;

     // check if they are vector operations:
     if (width = 1) and (LineWidth = sizeof(double)) then
     begin
          width := Height;
          height := 1;
          LineWidth := width*sizeof(double) + (width and $03)*sizeof(double);
     end;

     if (NativeUint(dest) and $0000001F = 0) and (LineWidth and $0000001F = 0)
     then
         Result := AVXMatrixElementwiseNorm2Aligned(dest, LineWidth, width, height)
     else
         Result := AVXMatrixElementwiseNorm2UnAligned(dest, LineWidth, width, height);

     if doSqrt then
        Result := Sqrt(Result);
end;


procedure AVXMatrixAdd(dest : PDouble; destLineWidth : NativeInt; mt1, mt2 : PDouble; width : NativeInt; height : NativeInt; LineWidth1, LineWidth2 : NativeInt);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (NativeUint(mt1) and $0000001F = 0) and (NativeUint(mt2) and $0000001F = 0) and (NativeUint(dest) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (LineWidth1 and $0000001F = 0) and (LineWidth2 and $0000001F = 0)
     then
         AVXMatrixAddAligned(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2)
     else
         AVXMatrixAddUnAligned(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2);
end;

procedure AVXMatrixSub(dest : PDouble; destLineWidth : NativeInt; mt1, mt2 : PDouble; width : NativeInt; height : NativeInt; LineWidth1, LineWidth2 : NativeInt);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (NativeUint(mt1) and $0000001F = 0) and (NativeUint(mt2) and $0000001F = 0) and (NativeUint(dest) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (LineWidth1 and $0000001F = 0) and (LineWidth2 and $0000001F = 0)
     then
         AVXMatrixSubAligned(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2)
     else
         AVXMatrixSubUnAligned(dest, destLineWidth, mt1, mt2, width, height, LineWidth1, LineWidth2);
end;

procedure AVXMatrixSubVec(A : PDouble; LineWidthA : NativeInt; B : PDouble; incX : NativeInt; width, Height : NativeInt; rowWise : Boolean);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (NativeUint(A) and $0000001F = 0) and (NativeUint(B) and $0000001F = 0) and
        (LineWidthA and $0000001F = 0)
     then
     begin
          if rowWise then
          begin
               if incx = sizeof(double)
               then
                   AVXMatrixSubVecAlignedVecRow(A, LineWidthA, B, incX, Width, Height)
               else
                   AVXMatrixSubVecAlignedRow(A, LineWidthA, B, incX, Width, Height)
          end
          else
              AVXMatrixSubVecAlignedCol(A, LineWidthA, B, incX, Width, Height);
     end
     else
     begin
          if rowWise then
          begin
               if incx = sizeof(double)
               then
                   AVXMatrixSubVecUnAlignedVecRow(A, LineWidthA, B, incX, Width, Height)
               else
                   AVXMatrixSubVecUnAlignedRow(A, LineWidthA, B, incX, Width, Height)
          end
          else
              AVXMatrixSubVecUnAlignedCol(A, LineWidthA, B, incX, Width, Height)
     end;
end;

procedure AVXMatrixAddVec(A : PDouble; LineWidthA : NativeInt; B : PDouble; incX : NativeInt; width, Height : NativeInt; rowWise : Boolean);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (NativeUint(A) and $0000001F = 0) and (NativeUint(B) and $0000001F = 0) and
        (LineWidthA and $0000001F = 0)
     then
     begin
          if rowWise then
          begin
               if incx = sizeof(double)
               then
                   AVXMatrixAddVecAlignedVecRow(A, LineWidthA, B, incX, Width, Height)
               else
                   AVXMatrixAddVecAlignedRow(A, LineWidthA, B, incX, Width, Height)
          end
          else
              AVXMatrixAddVecAlignedCol(A, LineWidthA, B, incX, Width, Height);
     end
     else
     begin
          if rowWise then
          begin
               if incx = sizeof(double)
               then
                   AVXMatrixAddVecUnAlignedVecRow(A, LineWidthA, B, incX, Width, Height)
               else
                   AVXMatrixAddVecUnAlignedRow(A, LineWidthA, B, incX, Width, Height)
          end
          else
              AVXMatrixAddVecUnAlignedCol(A, LineWidthA, B, incX, Width, Height)
     end;
end;

function AVXMatrixMax(mt : PDouble; width, height : NativeInt; const LineWidth : NativeInt) : double;
begin
     Result := -MaxDouble;
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= LineWidth), 'Dimension error');

     if (NativeUint(mt) and $0000001F = 0) and (LineWidth and $0000001F = 0)
     then
         Result := AVXMatrixMaxAligned(mt, width, height, LineWidth)
     else
         Result := AVXMatrixMaxUnAligned(mt, width, height, LineWidth);
end;

function AVXMatrixMin(mt : PDouble; width, height : NativeInt; const LineWidth : NativeInt) : double;
begin
     Result := MaxDouble;
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= LineWidth), 'Dimension error');

     if (NativeUint(mt) and $0000001F = 0) and (LineWidth and $0000001F = 0)
     then
         Result := AVXMatrixMinAligned(mt, width, height, LineWidth)
     else
         Result := AVXMatrixMinUnAligned(mt, width, height, LineWidth);
end;

procedure AVXMatrixMin(dest : PDouble; const LineWidth : NativeInt; width, height : NativeInt; minVal : double);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= LineWidth), 'Dimension error');

     if (NativeUint(dest) and $0000001F = 0) and (LineWidth and $0000001F = 0)
     then
         AVXMatrixMinValAligned(dest, lineWidth, width, height, minVal)
     else
         AVXMatrixMinValUnAligned(dest, LineWidth, width, height, minVal);
end;

procedure AVXMatrixMax(dest : PDouble; const LineWidth : NativeInt; width, height : NativeInt; maxVal : double);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= LineWidth), 'Dimension error');

     if (NativeUint(dest) and $0000001F = 0) and (LineWidth and $0000001F = 0)
     then
         AVXMatrixMaxValAligned(dest, lineWidth, width, height, maxVal)
     else
         AVXMatrixMaxValUnAligned(dest, LineWidth, width, height, maxVal);
end;

function AVXMatrixSumSum(src : PDouble; srcLineWidth : NativeInt; Width, Height : NativeInt): double;
begin
     Result := 0;
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= srcLineWidth), 'Dimension error');

     if (NativeUint(src) and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
     then
         Result := AVXMatrixSumAligned(src, srcLineWidth, width, height)
     else
         Result := AVXMatrixSumUnAligned(src, srcLineWidth, width, height);
end;

procedure AVXMatrixTranspose(dest : PDouble; const destLineWidth : NativeInt; mt : PDouble; const LineWidth : NativeInt; width : NativeInt; height : NativeInt);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= LineWidth), 'Dimension error');

     if (width > 1) and (height > 1) then
     begin
          if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(mt) and $0000001F = 0) and
             (destLineWidth and $0000001F = 0) and (LineWidth and $0000001F = 0)
          then
              AVXMatrixTransposeAligned(dest, destLineWidth, mt, LineWidth, width, height)
          else
              AVXMatrixTransposeUnAligned(dest, destLineWidth, mt, LineWidth, width, height);
     end
     else
         GenericMtxTranspose(dest, destLineWidth, mt, LineWidth, width, height);
end;

procedure AVXMatrixSum(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= srcLineWidth), 'Dimension error');
     assert((rowWise and (destLineWidth >= sizeof(double))) or (not rowWise and (destLineWidth >= width*sizeof(double))), 'Dimension error');

     // check if they are vector operations:
     if (width = 1) and (srcLineWidth = sizeof(double)) and not RowWise then
     begin
          width := Height;
          height := 1;
          srcLineWidth := width*sizeof(double) + (width and 1)*sizeof(double);
          destLineWidth := srcLineWidth;
          RowWise := True;
     end;

     if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(src) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
     then
     begin
          if RowWise
          then
              AVXMatrixSumRowAligned(dest, destLineWidth, Src, srcLineWidth, width, height)
          else
              AVXMatrixSumColumnAligned(dest, destLineWidth, Src, srcLineWidth, width, height);
     end
     else
     begin
          if RowWise
          then
              AVXMatrixSumRowUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height)
          else
              AVXMatrixSumColumnUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height);
     end;
end;

procedure AVXMatrixCumulativeSum(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= srcLineWidth), 'Dimension error');
     assert((rowWise and (destLineWidth >= sizeof(double))) or (not rowWise and (destLineWidth >= width*sizeof(double))), 'Dimension error');

     // check if we have vector operations:
     if (width = 1) and (srcLineWidth = sizeof(double)) and not RowWise then
     begin
          width := Height;
          height := 1;
          srcLineWidth := width*sizeof(double) + (width and 1)*sizeof(double);
          destLineWidth := srcLineWidth;
          RowWise := True;
     end;

     if RowWise
     then
         AVXMatrixCumulativeSumRow(dest, destLineWidth, Src, srcLineWidth, width, height)
     else
     begin
          if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(src) and $0000001F = 0) and
             (destLineWidth and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
          then
              AVXMatrixCumulativeSumColumnAligned(dest, destLineWidth, Src, srcLineWidth, width, height)
          else
              AVXMatrixCumulativeSumColumnUnaligned(dest, destLineWidth, Src, srcLineWidth, width, height);
     end;
end;

procedure AVXMatrixDifferentiate(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= srcLineWidth), 'Dimension error');
     assert((rowWise and (destLineWidth >= sizeof(double))) or (not rowWise and (destLineWidth >= width*sizeof(double))), 'Dimension error');

     // check if we have vector operations:
     if (width = 1) and (srcLineWidth = sizeof(double)) and not RowWise then
     begin
          width := Height;
          height := 1;
          srcLineWidth := width*sizeof(double) + (width and 1)*sizeof(double);
          destLineWidth := srcLineWidth;
          RowWise := True;
     end;

     if RowWise
     then
         AVXMatrixDifferentiateRow(dest, destLineWidth, Src, srcLineWidth, width, height)
     else
     begin
          if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(src) and $0000001F = 0) and
             (destLineWidth and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
          then
              AVXMatrixDifferentiateColumnAligned(dest, destLineWidth, Src, srcLineWidth, width, height)
          else
              AVXMatrixDifferentiateColumnUnaligned(dest, destLineWidth, Src, srcLineWidth, width, height);
     end;
end;

procedure AVXMatrixMean(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= srcLineWidth), 'Dimension error');
     assert((rowWise and (destLineWidth >= sizeof(double))) or (not rowWise and (destLineWidth >= width*sizeof(double))), 'Dimension error');

     // check if they are vector operations:
     if (width = 1) and (srcLineWidth = sizeof(double)) and not RowWise then
     begin
          width := Height;
          height := 1;
          srcLineWidth := width*sizeof(double) + (width and 1)*sizeof(double);
          destLineWidth := srcLineWidth;
          RowWise := True;
     end;

     if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(src) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
     then
     begin
          if RowWise
          then
              AVXMatrixMeanRowAligned(dest, destLineWidth, Src, srcLineWidth, width, height)
          else
              AVXMatrixMeanColumnAligned(dest, destLineWidth, Src, srcLineWidth, width, height);
     end
     else
     begin
          if RowWise
          then
              AVXMatrixMeanRowUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height)
          else
              AVXMatrixMeanColumnUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height);
     end;
end;

procedure AVXMatrixVar(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean; unbiased : boolean);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= srcLineWidth), 'Dimension error');
     assert((rowWise and (destLineWidth >= sizeof(double))) or (not rowWise and (destLineWidth >= width*sizeof(double))), 'Dimension error');

     // check if they are vector operations:
     if (width = 1) and (srcLineWidth = sizeof(double)) and not RowWise then
     begin
          width := Height;
          height := 1;
          srcLineWidth := width*sizeof(double) + (width and 1)*sizeof(double);
          destLineWidth := srcLineWidth;
          RowWise := True;
     end;

     if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(src) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
     then
     begin
          if RowWise
          then
              AVXMatrixVarRowAligned(dest, destLineWidth, Src, srcLineWidth, width, height, unbiased)
          else
              AVXMatrixVarColumnAligned(dest, destLineWidth, Src, srcLineWidth, width, height, unbiased);
     end
     else
     begin
          if RowWise
          then
              AVXMatrixVarRowUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height, unbiased)
          else
              AVXMatrixVarColumnUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height, unbiased);
     end;
end;

procedure AVXMatrixMeanVar(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean; unbiased : boolean);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= srcLineWidth), 'Dimension error');
     assert((rowWise and (destLineWidth >= 2*sizeof(double))) or (not rowWise and (destLineWidth >= width*sizeof(double))), 'Dimension error');

     // check if they are vector operations:
     if (width = 1) and (srcLineWidth = sizeof(double)) and not RowWise then
     begin
          width := Height;
          height := 1;
          srcLineWidth := width*sizeof(double) + (width and 1)*sizeof(double);
          RowWise := True;
     end;

     if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(src) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
     then
     begin
          if RowWise
          then
              AVXMatrixMeanVarRowAligned(dest, destLineWidth, Src, srcLineWidth, width, height, unbiased)
          else
              AVXMatrixMeanVarColumnAligned(dest, destLineWidth, Src, srcLineWidth, width, height, unbiased);
     end
     else
     begin
          if RowWise
          then
              AVXMatrixMeanVarRowUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height, unbiased)
          else
              AVXMatrixMeanVarColumnUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height, unbiased);
     end;
end;

procedure AVXMatrixNormalize(dest : PDouble; destLineWidth : NativeInt; Src : PDouble; srcLineWidth : NativeInt; width, height : NativeInt; RowWise : boolean);
begin
     if (width = 0) or (height = 0) then
        exit;
     assert((width*sizeof(double) <= srcLineWidth) and (width*sizeof(double) <= destLineWidth), 'Dimension error');

     // check if they are vector operations:
     if (width = 1) and (srcLineWidth = sizeof(double)) and not RowWise then
     begin
          width := Height;
          height := 1;
          srcLineWidth := width*sizeof(double) + (width and 1)*sizeof(double);
          destLineWidth := srcLineWidth;
          RowWise := True;
     end;

     if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(src) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
     then
     begin
          if RowWise
          then
              AVXMatrixNormalizeRowAligned(dest, destLineWidth, Src, srcLineWidth, width, height)
          else
              AVXMatrixNormalizeColumnAligned(dest, destLineWidth, Src, srcLineWidth, width, height);
     end
     else
     begin
          if RowWise
          then
              AVXMatrixNormalizeRowUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height)
          else
              AVXMatrixNormalizeColumnUnAligned(dest, destLineWidth, Src, srcLineWidth, width, height);
     end;
end;

procedure AVXMatrixCopy(Dest : PDouble; destLineWidth : NativeInt; src : PDouble; srcLineWidth : NativeInt; Width, Height : NativeInt);
begin
     if (width = 0) or (height = 0) then
        exit;

     // check if we have a block operation
     if (width*sizeof(double) = srcLineWidth) and (width*sizeof(double) = destLineWidth) then
     begin
          width := Height*width;
          height := 1;
          srcLineWidth := (width + (width and $03))*sizeof(double);
          destLineWidth := srcLineWidth;
     end;

     (* todo: check if it's really faster... according to intel software optimiziation manual it's around factor 1.02 against AVX/SSE movs at memblocks > 2kB
     if (width > 64) // and (width < maxcopy block
     then
         ASMCopyRepMov( dest, destLineWidth, src, srcLineWidth, width, height )
     else *) if (NativeUint(Dest) and $0000001F = 0) and (NativeUint(src) and $0000001F = 0) and
        (destLineWidth and $0000001F = 0) and (srcLineWidth and $0000001F = 0)
     then
         AVXMatrixCopyAligned(dest, destLineWidth, src, srcLineWidth, width, height)
     else
         AVXMatrixCopyUnAligned(dest, destLineWidth, src, srcLineWidth, width, height);
end;

procedure AVXMatrixInit( dest : PDouble; destLineWidth : NativeInt; Width, Height : NativeInt; const value : double );
begin
     if (width = 0) or (height = 0) then
        exit;

     // check if they are vector operations:
     if destLineWidth = width*sizeof(double)  then
     begin
          width := Height*Width;
          height := 1;
          destLineWidth := (width + 4 - width and $03)*sizeof(double);
     end;

     if (NativeUint(Dest) and $0000001F = 0) and (destLineWidth and $0000001F = 0)
     then
         AVXMatrixInitAligned(dest, destLineWidth, width, height, value)
     else
         AVXMatrixInitUnAligned(dest, destLineWidth, width, height, value);
end;

procedure AVXRowSwap(A, B : PDouble; width : NativeInt);
begin
     if (width = 0) then
        exit;

     if (NativeUint(A) and $0000001F = 0) and (NativeUint(B) and $0000001F = 0)
     then
         AVXRowSwapAligned(A, B, Width)
     else
         AVXRowSwapUnAligned(A, B, Width);
end;

procedure AVXMatrixMultTransposed(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); overload;
begin
     if (width1 = 0) or (width2 = 0) or (height1 = 0) or (height2 = 0) then
        exit;
     assert((width1 = width2), 'Dimension error');
     assert((destLineWidth - height2*sizeof(double) >= 0) and (LineWidth1 >= width1*sizeof(double)) and (LineWidth2 >= width2*sizeof(double)), 'Line widths do not match');

     if (width1 = 2)
     then
         ASMMatrixMultTransposed(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2)
     else if (width1 < 2) or (width2 < 2) then
     begin
          // matrix/vector multiplication
          GenericMtxMultTransp(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2);
     end
     else
     begin
          // ########################################################################
          // ####  In this case mt2 is already transposed -> direct multiplication
          // check for alignment:
          if ((NativeUint(dest) and $0000001F) = 0) and ((NativeUint(mt1) and $0000001F) = 0) and ((NativeUint(mt2) and $0000001F) = 0) and
             ((destLineWidth and $0000001F) = 0) and ((LineWidth1 and $0000001F) = 0) and ((LineWidth2 and $0000001F) = 0) then
          begin
               if width1 and $0000000F = 0 then
               begin
                    if height2 and $01 = 1
                    then
                        AVXMatrixMultAlignedEvenW1OddH2TransposedMod16(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2)
                    else
                        AVXMatrixMultAlignedEvenW1EvenH2TransposedMod16(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2);
               end
               else
                   AVXMatrixMultAlignedTransposed(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2);
          end
          else
              AVXMatrixMultUnAlignedTransposed(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2);
     end;
end;

procedure AVXMatrixMult(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt; mem : PDouble); overload;
var mtx : PDouble;
    mtxLineWidth : NativeInt;
    help : NativeInt;
    aMem : Pointer;
begin
     if (width1 = 0) or (width2 = 0) or (height1 = 0) or (height2 = 0) then
     	  exit;
     assert((width1 = height2), 'Dimension error');
     assert((destLineWidth - Width2*sizeof(double) >= 0) and (LineWidth1 >= width1*sizeof(double)) and (LineWidth2 >= width2*sizeof(double)), 'Line widths do not match');

     if (width1 < 2) and (width2 < 2) then
     begin
          GenericMtxMult(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2);
     end
     else if (width1 < 2) or (width2 < 2) then
     begin
          // matrix/vector multiplication
          if width2 = 1
          then
              AVXMtxVecMult(dest, destLineWidth, mt1, mt2, LineWidth1, LineWidth2,  width1, height1, 1, 0)
          else
              GenericMtxMult(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2);
     end
     else
     begin
          // ########################################################################
          // ####  For all "bigger" matrices transpose first then multiply. It's always faster
          aMem := nil;
          mtxLineWidth := height2;
          if height2 and $03 <> 0 then
             mtxLineWidth := mtxLineWidth + 4 - (height2 and $03);
          mtxLineWidth := mtxLineWidth*sizeof(double);
          if Assigned(mem)
          then
              mtx := mem
          else
              mtx := MtxMallocAlign( width2*mtxLineWidth, aMem );
          assert(assigned(mtx), 'Error could not reserve transpose memory');
          AVXMatrixTranspose(mtx, mtxLineWidth, mt2, LineWidth2, width2, height2);
          //GenericMtxTranspose(mtx, mtxLineWidth, mt2, LineWidth2, width2, height2);
          help := width2;
          width2 := height2;
          height2 := help;

          AVXMatrixMultTransposed(dest, destLineWidth, mt1, mtx, width1, height1, width2, height2, LineWidth1, mtxLineWidth);

          if Assigned(aMem) then
             FreeMem(aMem);
     end;
end;

procedure AVXMatrixMult(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt); overload;
begin
     AVXMatrixMult(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2, nil);
end;

procedure InternalAVXStrassenMult(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt;
  width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt; mem : PDouble);
var a11, a12, a21, a22 : PDouble;
    b11, b12, b21, b22 : PDouble;
    s1, s2, s3, s4 : PDouble;
    t1, t2, t3, t4 : PDouble;
    P1, P2, P3, P4, P5, P6, P7 : PDouble;
    U1, U2, U3, U4, U5, U6, U7 : PDouble;
    c11, c12, c21, c22 : PDouble;
    k, m, n : NativeInt;
    lineK : NativeInt;
    lineN : NativeInt;
    x, y : PDouble;
    multLineW : NativeInt;
begin
     if (width1 <= cStrassenMinSize) or (height1 <= cStrassenMinSize) or (width2 <= cStrassenMinSize) then
     begin
          multLineW := Max(cStrassenMinSize, height2)*sizeof(double);
          AVXMatrixTranspose(mem, multLineW, mt2, LineWidth2, width2, height2);
          AVXMatrixMultTransposed(dest, destLineWidth, mt1, mem, width1, height1, height2, width2, LineWidth1, multLineW);
     end
     else
     begin
          k := width1 div 2;
          m := height1 div 2;
          n := width2 div 2;

          lineK := k*sizeof(double);
          lineN := n*sizeof(double);

          a11 := mt1;
          a12 := a11;
          inc(a12, k);
          a21 := mt1;
          inc(PByte(a21), m*LineWidth1);
          a22 := a21;
          inc(a22, k);

          b11 := mt2;
          b12 := b11;
          inc(b12, n);
          b21 := mt2;
          inc(PByte(b21), k*LineWidth2);
          b22 := b21;
          inc(b22, n);

          c11 := dest;
          c12 := c11;
          inc(c12, n);
          c21 := dest;
          inc(PByte(c21), m*destLineWidth);
          c22 := c21;
          inc(c22, n);

          x := mem;
          y := x;
          inc(Y, m*Max(k, n));

          S3 := X;
          T3 := Y;
          P7 := C21;
          S1 := X;
          T1 := Y;
          P5 := C22;
          S2 := X;
          T2 := Y;
          P6 := C12;
          S4 := X;
          P3 := C11;
          P1 := X;
          U2 := C12;
          U3 := C21;
          U4 := C12;
          U7 := C22;
          U5 := C12;
          T4 := Y;
          P4 := C11;
          U6 := C21;
          P2 := C11;
          U1 := C11;

          mem := Y;
          inc(mem, k*n);

          // memory efficient mult:

          // s3 = A11 - A21
          AVXMatrixSub(s3, lineK, a11, a21, k, m, LineWidth1, LineWidth1);
          // t3 = B22 - B12
          AVXMatrixSub(t3, lineN, B22, B12, n, k, LineWidth2, LineWidth2);
          // p7 = s3*t3
          InternalAVXStrassenMult(p7, destLineWidth, s3, t3, k, m, n, k, lineK, lineN, mem);
          // s1 = a21 + a22
          AVXMatrixAdd(s1, lineK, a21, a22, k, m, LineWidth1, LineWidth1);
          // t1 = b12 - b11
          AVXMatrixSub(t1, lineN, B12, B11, n, k, LineWidth2, LineWidth2);
          // p5 = s1*t1
          InternalAVXStrassenMult(p5, destLineWidth, s1, t1, k, m, n, k, lineK, lineN, mem);
          // s2 = S1 - A11
          AVXMatrixSub(s2, lineK, S1, A11, k, m, lineK, LineWidth1);
          // t2 = b22 - t1
          AVXMatrixSub(t2, lineN, B22, t1, n, k, LineWidth2, lineN);
          // p6 = s2*t2
          InternalAVXStrassenMult(p6, destLineWidth, s2, t2, k, m, n, k, lineK, lineN, mem);
          // s4 = A12 - S2
          AVXMatrixSub(s4, lineK, A12, S2, k, m, LineWidth1, lineK);
          // p3 = s4*b22
          InternalAVXStrassenMult(p3, destLineWidth, s4, b22, k, m, n, k, lineK, LineWidth2, mem);
          // p1 = A11*B11
          InternalAVXStrassenMult(p1, lineN, A11, B11, k, m, n, k, LineWidth1, LineWidth2, mem);
          // U2 = P1 + P6
          AVXMatrixAdd(U2, destLineWidth, P1, P6, n, m, LineN, destLineWidth);
          // U3 = U2 + P7
          AVXMatrixAdd(U3, destLineWidth, U2, P7, n, m, destLineWidth, destLineWidth);
          // U4 = U2 + P5
          AVXMatrixAdd(U4, destLineWidth, U2, P5, n, m, destLineWidth, destLineWidth);
          // U7 = U3 + P5
          AVXMatrixAdd(U7, destLineWidth, U3, P5, n, m, destLineWidth, destLineWidth);
          // U5 = U4 + P3
          AVXMatrixAdd(U5, destLineWidth, U4, P3, n, m, destLineWidth, destLineWidth);
          // t4 = T2 - B21
          AVXMatrixSub(t4, lineN, T2, B21, n, k, LineN, LineWidth2);
          // p4 = A22*t4
          InternalAVXStrassenMult(p4, destLineWidth, A22, t4, k, m, n, k, LineWidth1, lineN, mem);
          // U6 = U3 - P4
          AVXMatrixSub(U6, destLineWidth, U3, P4, n, m, destLineWidth, destLineWidth);
          // p2 = A12*B21
          InternalAVXStrassenMult(p2, destLineWidth, A12, B21, k, m, n, k, LineWidth1, LineWidth2, mem);
          // U1 = P1 + P2
          AVXMatrixAdd(U1, destLineWidth, P1, P2, n, m, lineN, destLineWidth);

          // tidy up work for uneven columns, rows....
          if ((width1 and $01) > 0) or ((height1 and $01) > 0) or ((width2 and $01) > 0) then
          begin
               // following the algorithm if all items are odd...:
               //
               //  A*B = [A1   ac    ][B1  bc  ] = [A1*B1   0]  +  Delta
               //        [ar'  alpha ][br' beta]   [  0     0]
               //
               // Delta = [ac   ]*[br' beta]   +   [  0     A1*bc]
               //         [alpha]                  [ar'*B1  ar'*bc]

               // we already have computed A1*B1...

               if ((width1 and $01) = 0) and ((width2 and $01) = 0) then
               begin
                    inc(PByte(dest), destLineWidth*(height1 - 1));
                    inc(PByte(A11), LineWidth1*(height1 - 1));
                    GenericMtxMult(dest, destLineWidth, A11, B11, width1, 1, width2, height2, LineWidth1, LineWidth2);
               end
               else if ((width1 and $01) = 0) and ((height1 and $01) = 0) then
               begin
                    inc(dest, (width2 - 1));
                    inc(B11, (width2 - 1));
                    GenericMtxMult(dest, destLineWidth, A11, B11, width1, height1, 1, height2, LineWidth1, LineWidth2);
               end
               else if ((height1 and $01) = 0) and ((width2 and $01) = 0) then
               begin
                    inc(A11, width1 - 1);
                    inc(PByte(B11), LineWidth2*(height2 - 1));
                    GenericMtxDeltaUpdate(dest, destLineWidth, A11, B11, width2, height1, LineWidth1);
               end
               else if ((width1 and $01) = 0) and ((height1 and $01) > 0) and ((width2 and $01) > 0) then
               begin
                    // last column [A]*bc
                    inc(dest, (width2 - 1));
                    inc(B11, (width2 - 1));
                    GenericMtxMult(dest, destLineWidth, A11, B11, width1, height1 - 1, 1, height2, LineWidth1, LineWidth2);
                    dec(B11, (width2 - 1));
                    dec(dest, (width2 - 1));

                    // [ar alpha]*[B bc]  (last line)
                    inc(PByte(dest), destLineWidth*(height1 - 1));
                    inc(PByte(A11), LineWidth1*(height1 - 1));
                    GenericMtxMult(dest, destLineWidth, A11, B11, width1, 1, width2, height2, LineWidth1, LineWidth2);
               end
               else
               begin
                    // all dimensions are odd!
                    // calc A1*bc
                    inc(dest, (width2 - 1));
                    inc(B11, (width2 - 1));
                    GenericMtxMult(dest, destLineWidth, A11, B11, width1 - 1, height1 - 1, 1, height2 - 1, LineWidth1, LineWidth2);
                    dec(B11, (width2 - 1));
                    dec(dest, (width2 - 1));

                    // calc ar'*B1 and ar'*bc
                    inc(PByte(dest), destLineWidth*(height1 - 1));
                    inc(PByte(A11), LineWidth1*(height1 - 1));
                    GenericMtxMult(dest, destLineWidth, A11, B11, width1 - 1, 1, width2, height2 - 1, LineWidth1, LineWidth2);

                    inc(dest, width2 - 1);
                    inc(B11, width2 - 1);
                    GenericMtxMult(dest, destLineWidth, A11, B11, width1 - 1, 1, 1, height2 - 1, LineWidth1, LineWidth2);

                    dec(dest, width2 - 1);
                    dec(PByte(dest), destLineWidth*(height1 - 1));
                    dec(PByte(A11), LineWidth1*(height1 - 1));
                    dec(B11, width2 - 1);

                    // last step is to add the vector product matrix to the existing sum...
                    inc(A11, width1 - 1);
                    inc(PByte(B11), LineWidth2*(height2 - 1));
                    GenericMtxDeltaUpdate(dest, destLineWidth, A11, B11, width2, height1, LineWidth1);
               end;
          end;
     end;
end;

procedure AVXStrassenMatrixMultiplication(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt);
var mem : PDouble;
    ptrMem : Pointer;
    memSize : NativeInt;
    m, k, n : NativeInt;
    lev : NativeInt;
begin
     // check the cutoff criterion:
     if (width1 <= cStrassenMinSize) or (height1 <= cStrassenMinSize) or (height2 <= cStrassenMinSize)
     then
         AVXMatrixMult(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2)
     else
     begin
          // calc the complete used additionaly memory
          memSize := 0;
          m := height1;
          k := width1;
          n := width2;
          lev := Min(m, Min(k, n));

          while lev > cStrassenMinSize do
          begin
               memSize := memSize + sizeof(double)*(m*max(k, n) + k*n);
               k := k shr 1;
               m := m shr 1;
               n := n shr 1;
               lev := lev shr 1;
          end;
          // additional memory used for the transposition
          memSize := memSize + Max(cStrassenMinSize*cStrassenMinSize, n*k)*sizeof(double);

          mem := MtxMallocAlign(memSize, ptrMem);
          try
             InternalAVXStrassenMult(Dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2, mem);
          finally
                 FreeMem(ptrMem);
          end;
     end;
end;

procedure AVXMatrixMultDirect(dest : PDouble; const destLineWidth : NativeInt; mt1, mt2 : PDouble; width1 : NativeInt; height1 : NativeInt; width2 : NativeInt; height2 : NativeInt; const LineWidth1, LineWidth2 : NativeInt);
begin
     if (width1 = 0) or (width2 = 0) or (height1 = 0) or (height2 = 0) then
        exit;
     assert((width1 = height2), 'Dimension error');
     assert((destLineWidth - Width2*sizeof(double) >= 0) and (LineWidth1 >= width1*sizeof(double)) and (LineWidth2 >= width2*sizeof(double)), 'Line widths do not match');

     if (width1 < 3) and (width2 < 3)
     then
         GenericMtxMult(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2)
     else if (width1 < 2) or (width2 < 2) then
     begin
          // matrix/vector multiplication
          if width2 = 1
          then
              AVXMtxVecMult(dest, destLineWidth, mt1, mt2, LineWidth1, LineWidth2, width1, height1, 1, 0)
          else
              GenericMtxMult(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2);
     end
     else
     begin
          // check for alignment:
          if ((NativeUint(dest) and $0000001F) = 0) and ((NativeUint(mt1) and $0000001F) = 0) and ((NativeUint(mt2) and $0000001F) = 0) and
             ((destLineWidth and $0000001F) = 0) and ((LineWidth1 and $0000001F) = 0) and ((LineWidth2 and $0000001F) = 0)
          then
              AVXMatrixMultAligned(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2)
          else
              AVXMatrixMultUnaligned(dest, destLineWidth, mt1, mt2, width1, height1, width2, height2, LineWidth1, LineWidth2)
     end;
end;

procedure AVXMtxVecMult(dest : PDouble; destLineWidth : NativeInt; mt1, v : PDouble; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : double);
begin
     if (width = 0) or (height = 0) then
        exit;

     if (LineWidthV = sizeof(double)) then
     begin
          if ((NativeUint(mt1) and $0000001F) = 0) and ((NativeUint(v) and $0000001F) = 0) and (LineWidthMT and $1F = 0)
          then
              AVXMatrixVectMultAlignedVAligned(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta)
          else
              AVXMatrixVectMultUnAlignedVAligned(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta);
     end
     else
         AVXMatrixVectMult(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta);
end;

// performs dest = beta*dest + mt1**T*v * alpha
procedure AVXMtxVecMultT(dest : PDouble; destLineWidth : NativeInt; mt1, v : PDouble; LineWidthMT, LineWidthV : NativeInt; width, height : NativeInt; alpha, beta : double);
begin
     if (width = 0) or (height = 0) then
        exit;

     // no speed gain agains the standard vect mul
     //if LineWidthV = sizeof(double)
//     then
//         ASMMatrixVectMultTDestVec(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta)
//     else
         AVXMatrixVectMultT(dest, destLineWidth, mt1, v, LineWidthMT, LineWidthV, width, height, alpha, beta);
end;

procedure AVXRank1Update(A : PDouble; const LineWidthA : NativeInt; width, height : NativeInt;
  X, Y : PDouble; incX, incY : NativeInt; alpha : double);
begin
     if (width <= 0) or (height <= 0) then
        exit;

     if incY <> sizeof(double) 
     then
         ASMRank1Update(A, LineWidthA, width, height, x, y, incx, incy, alpha)
     else if ((NativeUint(A) and $0000001F) = 0) and ((NativeUint(Y) and $0000001F) = 0) and (LineWidthA and $1F = 0)
     then
         AVXRank1UpdateSeqAligned(A, LineWidthA, width, height, x, y, incX, incY, alpha)
     else
         AVXRank1UpdateSeq(A, LineWidthA, width, height, x, y, incX, incY, alpha);
end;

procedure AVXSymRank2UpdateUpper( C : PDouble; LineWidthC : NativeInt; A : PDouble; LineWidthA : NativeInt;
  B : PDouble; LineWidthB : NativeInt; N : NativeInt; k : NativeInt );
begin
     if (N <= 0) or (k <= 0) then
        exit;

     AVXSymRank2UpdateUpperUnaligned( C, LineWidthC, A, LineWidthA, B, LineWidthB, N, k);
end;

function AVXMatrixVecDotMult( x : PDouble; incX : NativeInt; y : PDouble; incY : NativeInt; N : NativeInt ) : double;
begin
     if (incx = sizeof(double)) and (incy = sizeof(double)) then
     begin
          if (NativeUint(X) and $0000001F = 0) and (NativeUint(Y) and $0000001F = 0)
          then
              Result := AVXMatrixVecDotMultAligned(X, Y, N)
          else
              Result := AVXMatrixVecDotMultUnAligned(X, Y, N);
     end
     else
         Result := AVXMatrixVecDotMultUneven(X, Y, incX, incY, N);
end;

end.

