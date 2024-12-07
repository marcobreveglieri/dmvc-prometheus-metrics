unit MVCFramework.Middleware.Metrics;

interface

uses
  MVCFramework;

type

{ TMVCMetricsMiddlewareConfig }

  TMVCMetricsMiddlewareConfig = record
    HttpRequestDurationEnabled: Boolean;
    HttpRequestDurationCollector: string;
    PathInfo: string;
    constructor Create(const APathInfo: string);
  end;

{ Routines }

/// <summary>
///  Returns a new instance of DMVC middleware properly configured
///  to export metric values from Prometheus Client.
/// </summary>
/// <param name="APathInfo">Set the path that will expose the metrics.</param>
function GetMetricsMiddleware(const APathInfo: string = '/metrics'): IMVCMiddleware; overload;

/// <summary>
///  Returns a new instance of DMVC middleware configured as specified
///  to export metric values from Prometheus Client.
/// </summary>
/// <param name="AConfig">Specified the settings for this middleware.</param>
function GetMetricsMiddleware(const AConfig: TMVCMetricsMiddlewareConfig): IMVCMiddleware; overload;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.StrUtils,
  System.SysUtils,
  MVCFramework.Commons,
  Prometheus.Collectors.Histogram,
  Prometheus.Exposers.Text,
  Prometheus.Registry;

type

{ TMetricsMiddleware }

  /// <summary>
  ///  Implements a middleware to export metric values from Prometheus Client.
  /// </summary>
  TMetricsMiddleware = class(TInterfacedObject, IMVCMiddleware)
  private
    FConfig: TMVCMetricsMiddlewareConfig;
    procedure HttpRequestDurationHistogramAfterAction(AContext: TWebContext);
    procedure HttpRequestDurationHistogramBeforeAction(AContext: TWebContext);
  public
    constructor Create(const AConfig: TMVCMetricsMiddlewareConfig);
    procedure OnAfterControllerAction(Context: TWebContext;
      const AControllerQualifiedClassName: string; const AActionName: string;
      const AHandled: Boolean);
    procedure OnAfterRouting(Context: TWebContext; const AHandled: Boolean);
    procedure OnBeforeControllerAction(Context: TWebContext;
      const AControllerQualifiedClassName: string; const AActionNAme: string;
      var Handled: Boolean);
    procedure OnBeforeRouting(Context: TWebContext; var Handled: Boolean);
  end;

{ TMVCMetricsMiddlewareConfig }

constructor TMVCMetricsMiddlewareConfig.Create(const APathInfo: string);
begin
  PathInfo := IfThen(Length(APathInfo) > 0, APathInfo, '/metrics');
  HttpRequestDurationEnabled := False;
  HttpRequestDurationCollector := 'http_request_duration_seconds';
end;

{ TMetricsMiddleware }

constructor TMetricsMiddleware.Create(const AConfig: TMVCMetricsMiddlewareConfig);
begin
  inherited Create;
  FConfig := AConfig;
end;

procedure TMetricsMiddleware.HttpRequestDurationHistogramAfterAction(AContext: TWebContext);
begin
  // Get the request start date/time value as raw string from context data.
  var LTimeStampRaw: string;
  if not AContext.Data.TryGetValue('RequestStartTimeStamp', LTimeStampRaw) then
    Exit;
  // Convert the raw value from string to an effective date/time value.
  var LTimeStamp := StrToFloat(LTimeStampRaw);
  // Determine the request duration in seconds calling the appropriate function.
  var LDuration := SecondSpan(Now, TDateTime(LTimeStamp));
  // Find the appropriate histogram collector to store metric values.
  var LCollector := TCollectorRegistry.DefaultRegistry
    .GetCollector<THistogram>(FConfig.HttpRequestDurationCollector);
  // Register a histogram metric with default buckets and labels if not found.
  if not Assigned(LCollector) then
  begin
    LCollector := THistogram.Create(FConfig.HttpRequestDurationCollector,
        'Time taken to process request in seconds', [], ['path', 'status']);
    LCollector.Register();
  end;
  // Add the current duration to the histogram metric collector.
  LCollector
    .Labels([AContext.Request.PathInfo, IntToStr(AContext.Response.StatusCode)])
    .Observe(LDuration);
end;

procedure TMetricsMiddleware.HttpRequestDurationHistogramBeforeAction(AContext: TWebContext);
begin
  // Store the request start date/time to feed histogram metrics.
  AContext.Data['RequestStartTimeStamp'] := FloatToStr(Extended(Now));
end;

procedure TMetricsMiddleware.OnAfterControllerAction(Context: TWebContext;
  const AControllerQualifiedClassName, AActionName: string;
  const AHandled: Boolean);
begin
  if FConfig.HttpRequestDurationEnabled then
    HttpRequestDurationHistogramAfterAction(Context);
end;

procedure TMetricsMiddleware.OnAfterRouting(Context: TWebContext;
  const AHandled: Boolean);
begin
  // Do nothing.
end;

procedure TMetricsMiddleware.OnBeforeControllerAction(Context: TWebContext;
  const AControllerQualifiedClassName, AActionNAme: string;
  var Handled: Boolean);
begin
  if FConfig.HttpRequestDurationEnabled then
    HttpRequestDurationHistogramBeforeAction(Context);
end;

procedure TMetricsMiddleware.OnBeforeRouting(Context: TWebContext;
  var Handled: Boolean);
begin
  // Check whether the current path request matches the metrics one.
  if not SameText(Context.Request.PathInfo, FConfig.PathInfo) then
    Exit;

  // We create a stream that will contain metric values exposed as text,
  // using the appropriate exposer from Prometheus Client to render it.
  var LStream := TMemoryStream.Create;
  try
    var LExposer := TTextExposer.Create;
    try
      LExposer.Render(LStream, TCollectorRegistry.DefaultRegistry.Collect());
    finally
      LExposer.Free;
    end;
  except
    LStream.Free;
    raise;
  end;

  // Re-position the stream at start to avoid IIS not rendering metrics.
  LStream.Position := 0;

  // Let's send all the generated text to the client.
  Context.Response.SetContentStream(LStream,
    Format('%s; charset=%s', [TMVCMediaType.TEXT_PLAIN, TMVCCharSet.UTF_8]));
  Context.Response.Flush();

  // Set the request has fully handled.
  Handled := True;
end;

{ Routines }

function GetMetricsMiddleware(const APathInfo: string): IMVCMiddleware;
begin
  Result := TMetricsMiddleware.Create(
    TMVCMetricsMiddlewareConfig.Create(APathInfo)
  );
end;

function GetMetricsMiddleware(const AConfig: TMVCMetricsMiddlewareConfig): IMVCMiddleware; overload;
begin
  Result := TMetricsMiddleware.Create(AConfig);
end;

end.
