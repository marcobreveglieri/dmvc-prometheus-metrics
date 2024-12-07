unit WebModules.App;

interface

uses
  System.Classes, System.SysUtils, Web.HTTPApp,
  MVCFramework;

type

{ TAppWebModule }

  TAppWebModule = class(TWebModule)
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
  private
    FEngine: TMVCEngine;
  end;

var
  WebModuleClass: TComponentClass = TAppWebModule;

implementation

{$R *.dfm}

uses
  MVCFramework.Middleware.Metrics,
  Prometheus.Collectors.Histogram,
  Prometheus.Collectors.Counter,
  Controllers.Demo;

{ TAppWebModule }

procedure TAppWebModule.WebModuleCreate(Sender: TObject);
var
  Buckets: TArray<Double>;
begin
  // Creates the Delphi MVC Framework server application engine.
  FEngine := TMVCEngine.Create(Self);
  Buckets := [0.2, 0.5, 0.75, 1, 2, 5, 10];

  // Add the metrics middleware! It will export all values using the
  // default endpoint '/metrics' but you can change it as shown below:
  FEngine.AddMiddleware(GetMetricsMiddleware('/metrics'));

  // Add a sample controller.
  FEngine.AddController(TDemoController);

  // Configure a sample counter metric for later use with some labels
  // and register it into the default collector registry.
  TCounter
    .Create('http_requests_count', 'Received HTTP request count', ['path', 'status'])
    .Register();

  // Register sample histogram metric with defined buckets and labels of path/status
  THistogram
    .Create('http_request_duration_seconds', 'Time taken to process request - in seconds', Buckets, ['path', 'status'])
    .Register()
end;

procedure TAppWebModule.WebModuleDestroy(Sender: TObject);
begin
  FEngine.Free;
end;

end.
