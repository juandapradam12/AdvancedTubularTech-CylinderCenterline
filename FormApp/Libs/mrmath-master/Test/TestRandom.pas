// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2015, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################

unit TestRandom;

interface


{$IFDEF MACOS}
   {$DEFINE FMX}
{$ENDIF}

// ###########################################
// #### Simple random generator tests (only functional tests no randomness tests!)
// ###########################################

uses {$IFDEF FPC} testregistry, {$ELSE} {$IFDEF FMX}DUnitX.TestFramework {$ELSE}TestFramework {$ENDIF}, {$ENDIF}
     BaseMatrixTestCase, Classes, SysUtils, Types;

type
  {$IFDEF FMX} [TestFixture] {$ENDIF}
  TestRandomOperations = class(TBaseMatrixTestCase)
  published
    procedure TestSystemRandom;
    procedure TestHardwareRandom;
    procedure TestMersenneTwister;
    procedure TestMersenneTwisterStdTest;
    procedure TestChaCha;
    procedure TestChaChaBig;
    procedure TestOSRandom;
    procedure TestInt64Rnd;
    procedure TestGaussRnd;
  end;

implementation

uses RandomEng, CPUFeatures, MtxTimer, MathUtilFunc, MatrixASMStubSwitch,
     MatrixConst;

const cNumRandNum = 1000000;

{ TestMatrixOperations }

procedure TestRandomOperations.TestChaCha;
var gen : TRandomGenerator;
    cnt : integer;
    outputPas : Array[0..255] of integer;
    outputSSE : Array[0..255] of integer;
begin
     gen := TRandomGenerator.Create(raChaCha);
     try
        gen.SetCpuInstrSet(TChaChaCPUInstrType.itFPU);
        gen.Init(7);
        for cnt := 0 to High(outputPas) do
        begin
             outputPas[cnt] := gen.RandInt($7F);
        end;
     finally
            gen.Free;
     end;

     gen := TRandomGenerator.Create(raChaCha);
     try
        gen.SetCpuInstrSet(TChaChaCPUInstrType.itSSE);
        gen.Init(7);

        for cnt := 0 to High(outputSSE) do
            outputSSE[cnt] := gen.RandInt($7F);
     finally
            gen.Free;
     end;

     for cnt := 0 to High(outputPas) do
     begin
          Status(Format('%d, %d', [outputpas[cnt], outputSSE[cnt]]));
          Check(outputPas[cnt] = outputSSE[cnt], 'ChaCha Random failed');
     end;

     if IsAVXPresent then
     begin
          gen := TRandomGenerator.Create(raChaCha);
          try
             gen.SetCpuInstrSet(TChaChaCPUInstrType.itAVX2);

             gen.Init(7);

             for cnt := 0 to High(outputSSE) do
                 outputSSE[cnt] := gen.RandInt($7F);
          finally
                 gen.Free;
          end;
          Status('');
          for cnt := 0 to High(outputPas) do
          begin
               Status(Format('%d, %d', [outputpas[cnt], outputSSE[cnt]]));
               Check(outputPas[cnt] = outputSSE[cnt], 'ChaCha Random failed');
          end;
     end;
end;

procedure TestRandomOperations.TestChaChaBig;
var gen : TRandomGenerator;
    s1, s2, e1, e2 : Int64;
    freq : int64;
    pasRnd, sseRnd : LongWord;
    i : Integer;
begin
     freq := mtxFreq;

     gen := TRandomGenerator.Create(raChaCha);
     try
        gen.SetCpuInstrSet(TChaChaCPUInstrType.itFPU);

        gen.Init( 175 );
        s1 := MtxGetTime;
        for i := 0 to cNumRandNum - 1 do
            pasRnd := gen.RandLW($FFFFFFFF);
        e1 := MtxGetTime;
     finally
            gen.Free;
     end;

     gen := TRandomGenerator.Create(raChaCha);
     try
        gen.SetCpuInstrSet(TChaChaCPUInstrType.itSSE);
        gen.Init( 175 );
        s2 := MtxGetTime;
        for i := 0 to cNumRandNum - 1 do
            sseRnd := gen.RandLW($FFFFFFFF);
        e2 := MtxGetTime;
     finally
            gen.Free;
     end;

     Status(Format('ChaChaRnd of %d elements took pas: %.3f, sse: %.3f', [cNumRandNum, (e1 - s1)*1000/freq, (e2 - s2)*1000/freq]));
     check( sseRnd = pasRnd, 'Large ChaCha Rnd failed');

     if IsAVXPresent then
     begin
          gen := TRandomGenerator.Create(raChaCha);
          try
             gen.SetCpuInstrSet(TChaChaCPUInstrType.itAVX2);
             gen.Init( 175 );
             s2 := MtxGetTime;
             for i := 0 to cNumRandNum - 1 do
                 sseRnd := gen.RandLW($FFFFFFFF);
             e2 := MtxGetTime;
          finally
                 gen.Free;
          end;

          Status(Format('ChaChaRnd of %d elements took pas: %.3f, avx: %.3f', [cNumRandNum, (e1 - s1)*1000/freq, (e2 - s2)*1000/freq]));
          check( sseRnd = pasRnd, 'Large ChaCha Rnd failed');
     end;
end;

procedure TestRandomOperations.TestGaussRnd;
var gen : TRandomGenerator;
    c : TDoubleDynArray;
    i: Integer;
    meanvarrec : TMeanVarRec;
begin
     gen := TRandomGenerator.Create(raMersenneTwister);
     try
        gen.Init(455);
        SetLength(c, 10000);
        for i := 0 to Length(c) - 1 do
            c[i] := 1 + gen.RandGauss*2;

        // stdev 2, mean 1
        MatrixMeanVar( @meanvarrec, sizeof(meanvarrec), @c[0], Length(c)*sizeof(double), Length(c), 1, True, True);

        Status( Format('Mean: %.5f, Var: %.5f, Stdev: %.5f', [meanVarRec.aMean, meanVarRec.aVar, sqrt(meanVarRec.aVar)]));
 
        Check( abs(meanvarrec.aMean - 1) < 0.1, 'Gauss mean failed');
        Check( abs(sqrt(meanvarrec.aVar) - 2) < 0.1, 'Gauss var failed');
     finally
            gen.Free;
     end;
end;

procedure TestRandomOperations.TestHardwareRandom;
var gen : TRandomGenerator;
    start, stop : Int64;
    cnt : integer;
begin
     if IsHardwareRNDSupport then
     begin
          gen := TRandomGenerator.Create;
          gen.RandMethod := raIntelRAND;

          for cnt := 0 to 10 do
          begin
               Status(IntToStr(cnt) + ': ' + IntToStr(gen.RandInt(20)));
          end;


          start := MtxGetTime;
          for cnt := 0 to cNumRandNum - 1 do
              gen.Random;
          stop := MtxGetTime;

          gen.Free;
          Status(Format('Hardware random 1 million times: %.2f', [(stop - start)/mtxFreq*1000]));
     end
     else
     begin
          Status('No hardware random support detected' );
     end;
end;

procedure TestRandomOperations.TestMersenneTwister;
var gen : TRandomGenerator;
    start, stop : Int64;
    cnt : integer;
begin
     gen := TRandomGenerator.Create;
     gen.RandMethod := raMersenneTwister;

     start := MtxGetTime;
     for cnt := 0 to cNumRandNum - 1 do
         gen.Random;
     stop := MtxGetTime;

     gen.Free;
     Status(Format('Mersenne Twister random 1 million times: %.2f', [(stop - start)/mtxFreq*1000]));
end;


// ###########################################
// #### Mersenne standard test
// #### the test is based on the output file that can be found on: 
// #### http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/CODES/mt19937ar.out
// #### with the difference, that the floating point random numbers are genereated from the
// #### higher precission method genrand_res53
// ###########################################

procedure TestRandomOperations.TestMersenneTwisterStdTest;
const initKey : Array[0..3] of LongWord = ($123, $234, $345, $456);
var s : AnsiString;
    gen : TRandomGenerator;
    cnt : integer;
    buf1, buf2 : TByteDynArray;
    ft : TFormatSettings;
begin
     ft := GetLocalFMTSet;
     ft.DecimalSeparator := '.';

     // produce the exact same output as in mt19937ar.c
     gen := TRandomGenerator.Create;

     gen.RandMethod := raMersenneTwister;
     gen.InitMersenneByArr( initKey );

     s := '1000 outputs of genrand_int32()' + #13#10;
     with TFileStream.Create('marsenneTwist.txt', fmCreate or fmOpenWrite) do
     try
        WriteBuffer(s[1], length(s));

        for cnt := 0 to 200 - 1 do
        begin
             // fpc produces here an range check error?!?!
             s := AnsiString( Format('%10u %10u %10u %10u %10u ' + #13#10, [Int64(gen.RandLW($FFFFFFFF)) ,
                         Int64(gen.RandLW($FFFFFFFF)), Int64(gen.RandLW($FFFFFFFF)), Int64(gen.RandLW($FFFFFFFF)), Int64(gen.RandLW($FFFFFFFF))], ft));
             WriteBuffer(s[1], Length(s));
        end;

        s := #13#10 + '1000 outputs of genrand_real2()' + #13#10;
        WriteBuffer(s[1], Length(s));
        for cnt := 0 to 200 - 1 do
        begin
             s := AnsiString( Format('%10.8f %10.8f %10.8f %10.8f %10.8f ' + #13#10, [gen.Random, gen.Random, gen.Random, gen.Random, gen.Random], ft));
             WriteBuffer(s[1], Length(s));
        end;
     finally
            Free;
     end;

     gen.Free;

     // now do a binary compare of the original and the current file
     with TFileStream.Create(BaseDataPath + 'marsenneTwistOrig.txt', fmOpenRead) do
     try
        SetLength(buf1, Size);
        ReadBuffer(buf1[0], Size);
     finally
            Free;
     end;

     with TFileStream.Create('marsenneTwist.txt', fmOpenRead) do
     try
        SetLength(buf2, Size);
        ReadBuffer(buf2[0], Size);
     finally
            Free;
     end;

     Check(Length(buf1) = Length(buf2), 'File size different');
     Check(CompareMem(@buf1[0], @buf2[0], Length(buf1)), 'Random output files differ - check marsenneTwistOrig.txt and marsenneTwist.txt for differences');
end;

procedure TestRandomOperations.TestOSRandom;
var gen : TRandomGenerator;
    start, stop : Int64;
    cnt : integer;
begin
     gen := TRandomGenerator.Create;
     gen.RandMethod := raOS;

     start := MtxGetTime;
     for cnt := 0 to cNumRandNum - 1 do
         gen.Random;
     stop := MtxGetTime;

     gen.Free;
     Status(Format('System random 1 million times: %.2f', [(stop - start)/mtxFreq*1000]));
end;

procedure TestRandomOperations.TestSystemRandom;
var gen : TRandomGenerator;
    start, stop : Int64;
    cnt : integer;
{$IFNDEF FPC}
    rnd1, rnd2 : LongInt;
{$ENDIF}
begin
     gen := TRandomGenerator.Create;
     gen.RandMethod := raSystem;

     {$IFNDEF FPC} // note: the linear congruent random number generator is only implemented in delphi
                   // afaik  FPC uses mersenne twister.

     gen.Init(301);
     RandSeed := 301;

     // check if the first 1000 values are the same

     for cnt := 0 to 1000 - 1 do
     begin
          rnd1 := gen.RandInt(1000000);
          rnd2 := Random(1000000);

          check(rnd1 = rnd2, 'Error pseudonumber generator differ');
     end;

     {$ENDIF}

     start := MtxGetTime;
     for cnt := 0 to cNumRandNum - 1 do
         gen.Random;
     stop := MtxGetTime;

     gen.Free;
     Status(Format('System random 1 million times: %.2f', [(stop - start)/mtxFreq*1000]));
end;

procedure TestRandomOperations.TestInt64Rnd;
var gen : TRandomGenerator;
    i: Integer;
    val1 : Int64;
    val2 : UInt64;
begin
     gen := TRandomGenerator.Create;
     gen.Init;

     for i := 0 to 100 - 1 do
     begin
          val1 := gen.RandInt64($7fffffffffffffff);
          val2 := gen.RandUint64($000FFFFFFFFFFFFF);
          Status(IntToStr(i) + ': ' + intToStr(val1) + ', ' + IntToStr(val2));
     end;

     gen.Free;
end;

initialization
{$IFNDEF FMX}
  RegisterTest(TestRandomOperations{$IFNDEF FPC}.Suite{$ENDIF});
{$ENDIF}

end.
