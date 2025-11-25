require_relative './index'

# Lambda handler entry point
$app ||= APIApp.new
$app = CorsMiddleware.new($app) unless $app.is_a?(CorsMiddleware)

def handler(event:, context:)
  method = event['httpMethod'] || 'GET'
  path = event['path'] || '/'
  
  env = {
    'REQUEST_METHOD' => method,
    'PATH_INFO' => path,
    'SCRIPT_NAME' => '',
    'SERVER_NAME' => event['headers']&.[]('host') || 'localhost',
    'SERVER_PORT' => '443',
    'SERVER_PROTOCOL' => 'HTTP/1.1',
    'rack.version' => [1, 3],
    'rack.input' => StringIO.new(event['body'] || ''),
    'rack.errors' => $stderr,
    'rack.multithread' => false,
    'rack.multiprocess' => false,
    'rack.run_once' => true
  }
  
  status, headers, body = $app.call(env)
  
  {
    statusCode: status,
    headers: headers,
    body: body.join
  }
end
