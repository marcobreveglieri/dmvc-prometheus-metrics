unit WebApp.WebModules.Main;

interface

uses
  System.Classes, System.SysUtils, Web.HTTPApp,
  MVCFramework;

type

{ TAppWebModule }

  TMainModule = class(TWebModule)
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
  private
    FEngine: TMVCEngine;
  end;

var
  WebModuleClass: TComponentClass = TMainModule;

implementation

{$R *.dfm}

uses
  Prometheus.Collectors.Counter,
  Prometheus.Registry,
  MVCFramework.Middleware.Metrics,
  WebApp.Controllers.Demo;

{ TAppWebModule }

procedure TMainModule.WebModuleCreate(Sender: TObject);
begin
  // Create the Delphi MVC Framework server application engine.
  FEngine := TMVCEngine.Create(Self);

  // Add the metrics middleware! It will export all values using the
  // default endpoint '/metrics' but you can change it as shown below:
  begin var LConfig := TMVCMetricsMiddlewareConfig.Create('/metrics');
    LConfig.HttpRequestDurationEnabled := True;
    LConfig.HttpRequestDurationCollector := 'http_request_duration_seconds';
    FEngine.AddMiddleware(GetMetricsMiddleware(LConfig));
  end;

  // Add a sample controller.
  FEngine.AddController(TDemoController);

  // Configure a sample counter metric for later use with some labels
  // and register it into the default collector registry.
  if not TCollectorRegistry.DefaultRegistry.HasCollector('http_requests_total') then
  begin
    TCounter
      .Create('http_requests_total', 'Received HTTP request count', ['path', 'status'])
      .Register();
  end;
end;

procedure TMainModule.WebModuleDestroy(Sender: TObject);
begin
  // Free the Delphi MVC Framework server application engine.
  FEngine.Free;
end;

end.
