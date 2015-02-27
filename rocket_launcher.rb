require "bundler/setup"
require "sinatra"

pid = nil
lastpid = nil

DEFAULT_UPSTREAM = "127.0.0.1"

get '/' do
  launcher = <<-html
  <form method="post" action="/">
    <button>Proxify</button>
  </form>
  html
  erb launcher
end

post '/' do
  Process.kill("SIGKILL", pid) if pid

  # request.ip isn't honouring proxy headers, so do it manually
  client_ip = @env['HTTP_X_FORWARDED_FOR'] || request.ip
  upstream_host = client_ip

  pid = spawn_proxy(upstream_host) if is_valid(upstream_host)

  pid ||= spawn_proxy

  if lastpid == pid
    resp = "<h2>No changes to proxy</h2><p>Techy stuff: did not launch em-proxy with upstream host '#{upstream_host}'; still PID #{pid}</p>"
  else
    resp = "<h2>Proxy configured!</h2><p>Techy stuff: em-proxy launched as PID #{pid}, using #{upstream_host || DEFAULT_UPSTREAM} as upstream proxy</p>"
  end

  lastpid = pid
  erb resp
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
