unit Controllers.Demo;

interface

uses
  MVCFramework,
  MVCFramework.Commons;

type

{ TDemoController }

  [MVCPath('/')]
  TDemoController = class(TMVCController)
  public
    [MVCPath('/')]
    [MVCHTTPMethod([httpGET])]
    procedure Index;

    [MVCPath('/hello')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN)]
    procedure HelloWorld;

    [MVCPath('/secret')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN)]
    procedure Secret;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  Prometheus.Collectors.Counter,
  Prometheus.Collectors.Histogram,
  Prometheus.Registry;

{ TDemoController }
procedure TDemoController.Index;
begin
  // Redirect the user to the "/hello" endpoint.
  Redirect('/hello');
end;

procedure TDemoController.HelloWorld;
begin
  // Get the metric counter from the default registry and increment it.
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_count')
    .Labels([Context.Request.PathInfo, IntToStr(HTTP_STATUS.OK)]) // path, status
    .Inc();

  // Render a sample string of text as the response.
  Render('Hello World! It''s ' + TimeToStr(Time) + ' in the DMVCFramework Land!');
end;

procedure TDemoController.Secret;
begin
  // Get the metric counter from the default registry and increment it.
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_count')
    .Labels([Context.Request.PathInfo, IntToStr(HTTP_STATUS.Unauthorized)]) // path, status
    .Inc();

  // Send a unauthorized status code.
  ResponseStatus(HTTP_STATUS.Unauthorized, 'You are not authorized');
end;

end.
