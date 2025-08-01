unit ReadDataUtils;

interface

uses
  SysUtils, Classes, Matrix;

function ReadPointCloudFromFile(const FilePath: string): TDoubleMatrix;
function ReadPointCloudFromFile_XE2(PointCloudFilename: string; XYZDelimiter: char; LocalePoint: string): TDoubleMatrix;
procedure PrintMatrix(const EV: TDoubleMatrix);

implementation


{
-----------------------------------------------------------------

Parts := Lines[i].Split([',']) DOES NOT WORK IN DELPHI XE2

Your computer setup requires commas in the float point.
USA computers will not.

See the new method for a method that works for both of us so that
I don't have to keep making this change.

-----------------------------------------------------------------
}


function ReadPointCloudFromFile(const FilePath: string): TDoubleMatrix;
  var
    Lines: TStringList;
    i, N: Integer;
    Parts: TArray<string>;
    X, Y, Z: array of Double;
  begin
    if not FileExists(FilePath) then
      raise Exception.Create('File not found: ' + FilePath);

    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(FilePath);
      if Lines.Count <= 1 then
        raise Exception.Create('No data after header.');

      N := Lines.Count - 1;
      SetLength(X, N);
      SetLength(Y, N);
      SetLength(Z, N);

      for i := 1 to N do
      begin
        Parts := Lines[i].Split([',']);
        X[i - 1] := StrToFloatDef(StringReplace(Parts[0], '.', ',', [rfReplaceAll]), 0);
        Y[i - 1] := StrToFloatDef(StringReplace(Parts[1], '.', ',', [rfReplaceAll]), 0);
        Z[i - 1] := StrToFloatDef(StringReplace(Parts[2], '.', ',', [rfReplaceAll]), 0);
      end;

      Result := TDoubleMatrix.Create(3, N);
      for i := 0 to N - 1 do
      begin
        Result[0, i] := X[i];
        Result[1, i] := Y[i];
        Result[2, i] := Z[i];
      end;

    finally
      Lines.Free;
    end;
  end;


{
-----------------------------------------------------------------

Parts := Lines[i].Split([',']) DOES NOT WORK IN DELPHI XE2

Your computer setup requires commas in the float point.
USA computers will not.

See the new method for a method that works for both of us so that
I don't have to keep making this change.

-----------------------------------------------------------------
}

function ReadPointCloudFromFile_XE2(PointCloudFilename: string; XYZDelimiter: char; LocalePoint: string): TDoubleMatrix;
var
  Lines: TStringList;
  i, N: Integer;
  Parts: TStringList;
  X, Y, Z: array of Double;
begin
  if not FileExists(PointCloudFilename) then
    raise Exception.Create('File not found: ' + PointCloudFilename);

  Lines := TStringList.Create;
  Parts := TStringList.Create;
  try
    Lines.LoadFromFile(PointCloudFilename);
    if Lines.Count <= 1 then
      raise Exception.Create('No data after header.');

    N := Lines.Count - 1;
    SetLength(X, N);
    SetLength(Y, N);
    SetLength(Z, N);

    for i := 1 to N do
    begin

      Parts.Delimiter := XYZDelimiter;
      Parts.DelimitedText := Lines[i];

      if LocalePoint <> '.' then
      begin
        X[i - 1] := StrToFloatDef(StringReplace(Parts[0], '.', LocalePoint, [rfReplaceAll]), 0);
        Y[i - 1] := StrToFloatDef(StringReplace(Parts[1], '.', LocalePoint, [rfReplaceAll]), 0);
        Z[i - 1] := StrToFloatDef(StringReplace(Parts[2], '.', LocalePoint, [rfReplaceAll]), 0);
      end else
      begin
        X[i - 1] := StrToFloat(Parts[0]);
        Y[i - 1] := StrToFloat(Parts[1]);
        Z[i - 1] := StrToFloat(Parts[2]);
      end;
    end;

    Result := TDoubleMatrix.Create(3, N);
    for i := 0 to N - 1 do
    begin
      Result[0, i] := X[i];
      Result[1, i] := Y[i];
      Result[2, i] := Z[i];
    end;

  finally
    Lines.Free;
    Parts.Free;
  end;
end;



procedure PrintMatrix(const EV: TDoubleMatrix);
var
  i, j: Integer;
begin
  Writeln('--- Matrix ---');
  Writeln(Format('Size: %d rows × %d columns', [EV.Height, EV.Width]));

  for i := 0 to EV.Height - 1 do
  begin
    Write(Format('Row %d: ', [i]));
    for j := 0 to EV.Width - 1 do
      Write(Format('%.6f  ', [EV[i, j]]));
    Writeln;
  end;
end;


end.

