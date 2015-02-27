require "bundler/setup"
require "sinatra"

pid = nil

get '/' do
  if params[:new] && pid
    Process.kill("SIGKILL", pid)

    # request.ip isn't honouring proxy headers, so do it manually
    client_ip = @env['HTTP_X_FORWARDED_FOR'] || request.ip
    host = params[:new] == 'ip' ? client_ip : params[:new]

    pid = spawn_proxy(host)
  end
  pid ||= spawn_proxy

  "em-proxy launched as PID #{pid}, using host '#{host}' as upstream proxy"
end

def spawn_proxy(host="127.0.0.1")
  Process.spawn("em-proxy -l 8080 -r #{host}:3000 -v")
end
