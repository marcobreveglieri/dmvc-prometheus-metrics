unit WebApp.Controllers.Demo;

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

    [MVCPath('/think')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.TEXT_PLAIN)]
    procedure Think;
  end;

implementation

uses
  System.Classes,
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
    .GetCollector<TCounter>('http_requests_total')
    .Labels([Context.Request.PathInfo, IntToStr(HTTP_STATUS.OK)]) // path, status
    .Inc();

  // Render a sample string of text as the response.
  Render('Hello World! It''s ' + TimeToStr(Time) + ' in the DMVCFramework Land!');
end;

procedure TDemoController.Secret;
begin
  // Get the metric counter from the default registry and increment it.
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_total')
    .Labels([Context.Request.PathInfo, IntToStr(HTTP_STATUS.Unauthorized)]) // path, status
    .Inc();

  // Send a unauthorized status code.
  ResponseStatus(HTTP_STATUS.Unauthorized, 'You are not authorized');
end;

procedure TDemoController.Think;
begin
  // Get the metric counter from the default registry and increment it.
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_total')
    .Labels([Context.Request.PathInfo, IntToStr(HTTP_STATUS.OK)]) // path, status
    .Inc();

  // Extracts the delay from query string params.
  var LDelay: Integer;
  if Context.Request.QueryStringParamExists('time') then
    LDelay := Context.Request.QueryStringParam('time').ToInteger
  else
    LDelay := 0;

  // Sorry... I think a lot...
  TThread.Sleep(LDelay);

  // Send a success response to the client.
  Render('Done! Sorry for the delay... :)');
end;

end.
