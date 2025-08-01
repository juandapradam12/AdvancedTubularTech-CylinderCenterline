program JDPMCylinderFitProject;

uses
  Vcl.Forms,
  FormJDPMCylinderFit in 'FormJDPMCylinderFit.pas' {Form_JDPMCylinderFit},
  PCAService in 'Services\PCAService.pas',
  PCAProjectionService in 'Services\PCAProjectionService.pas',
  CircleFitService in 'Services\CircleFitService.pas',
  PCAMultiPlaneIterationService in 'Services\PCAMultiPlaneIterationService.pas',
  InterceptService in 'Services\InterceptService.pas',
  CylinderLengthService in 'Services\CylinderLengthService.pas',
  ReadDataUtils in 'Utils\ReadDataUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm_JDPMCylinderFit, Form_JDPMCylinderFit);
  Application.Run;
end.
