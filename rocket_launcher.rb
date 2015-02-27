require "bundler/setup"
require "sinatra"

pid = nil
lastpid = nil

DEFAULT_UPSTREAM = "127.0.0.1"

get '/' do
  if params[:new]
    Process.kill("SIGKILL", pid) if pid

    # request.ip isn't honouring proxy headers, so do it manually
    client_ip = @env['HTTP_X_FORWARDED_FOR'] || request.ip
    upstream_host = params[:new] == 'ip' ? client_ip : params[:new]

    pid = spawn_proxy(upstream_host) if is_valid(upstream_host)
  end

  pid ||= spawn_proxy

  if lastpid == pid
    resp = "did not launch em-proxy with upstream host '#{upstream_host}'; still PID #{pid}"
  else
    resp = "em-proxy launched as PID #{pid}, using #{upstream_host || DEFAULT_UPSTREAM} as upstream proxy"
  end

  lastpid = pid
  resp
end

def spawn_proxy(upstream_host=DEFAULT_UPSTREAM)
  Process.spawn("em-proxy -l 8080 -r #{upstream_host}:3000 -v")
end

def is_valid(upstream_host)
  return false if upstream_host.nil?

  # Only support a limited set of IPs and hostnames
  return true if /^[0-9A-Za-z\.\-]+$/.match(upstream_host)

  return false
end
