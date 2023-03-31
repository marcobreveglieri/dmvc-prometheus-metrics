<div>  
  <img alt="Prometheus Client for Delphi" height="48" src="https://ucarecdn.com/a7019e45-d14b-47cd-8ceb-70ba7848f049/" style="vertical-align: middle">
  <h1>Delphi MVC Framework Prometheus Metrics middleware</h2>
  <em>Middleware for Prometheus Client to expose metrics using Delphi MVC framework</em>
</div>

## Prerequisites

This middleware is designed to work with [Delphi MVC Framework](https://github.com/danieleteti/delphimvcframework).

If you use another library to build Web Server applications in Delphi (like [Horse](https://github.com/HashLoad/horse), [MARS](https://github.com/andrea-magni/MARS), *Web Broker*, etc.), checkout if there are [samples](https://github.com/marcobreveglieri/prometheus-client-delphi/tree/main/Samples) that can help you out bootstrapping your application or ready-to-use [middlewares](https://github.com/marcobreveglieri/prometheus-client-delphi#middlewares) for your framework.

## How to install

To install this middleware in your project, download source code from GitHub and set the *library path* as usual,
or launch this command to get all the needed packages using [boss](https://github.com/HashLoad/boss) package manager:
``` sh
$ boss install marcobreveglieri/dmvc-prometheus-metrics
```

NOTE: if you download the package manually, also remember to get and configure the [Prometheus Client for Delphi library](https://github.com/marcobreveglieri/prometheus-client-delphi).

## Usage

To use this middleware, enable it calling **MVCEngine.AddMiddleware()** and passing the result of **GetMetricsMiddleware()**,
a function available from the unit *MVCFramework.Middleware.Metrics* that creates an instance of the middleware object properly
configured.

You can specify the path that exposes the metrics as a parameter or leave it blank to keep the default '/metrics' endpoint
(which is the default path scraped by Prometheus server when collecting metric values).

Then you can just declare the metrics you need registering them into the default collection registry.

```delphi
uses
  MVCFramework,
  MVCFramework.Middleware.Metrics,
  ...

begin
  Engine := TMVCEngine.Create(Self);

  Engine.AddMiddleware(GetMetricsMiddleware('/metrics'));

  TCounter
    .Create('http_requests_count', 'Received HTTP request count', ['path', 'status'])
    .Register();
end.
```

You can get a reference to your metrics inside controllers (or everywhere you need them).

```delphi
uses
  MVCFramework,
  Prometheus.Collectors.Counter,
  Prometheus.Registry,
  ...

procedure TDemoController.HelloWorld;
begin
  TCollectorRegistry.DefaultRegistry
    .GetCollector<TCounter>('http_requests_count')
    .Labels([Context.Request.PathInfo, IntToStr(HTTP_STATUS.OK)])
    .Inc();

  Render('Done!');
end;
```

## Test it!

By calling the route **/metrics** (or any different path specified when enabling the middleware)
you will get a plain text response that includes all the current metric values collected from the
default collector registry.

```text
# HELP http_requests_handled Received HTTP request count
# TYPE http_requests_handled counter
http_requests_handled{path="/hello",status="200"} 4
http_requests_handled{path="/secret",status="401"} 2
```

## Additional info

If you want to know more about Prometheus, visit the [official homepage](https://prometheus.io/) and download the right version of this tool.

This middleware also requires to install the [Prometheus Client for Delphi library](https://github.com/marcobreveglieri/prometheus-client-delphi)
and obviously [Delphi MVC Framework](https://github.com/danieleteti/delphimvcframework).

Visit these web sites for getting started and read additional documentation about Prometheus and its client library for Delphi.

**Happy coding! 🧑🏻‍💻**
