require "bundler/setup"
require "sinatra"

pid = nil

get '/' do
  if params[:new] && pid
    Process.kill("SIGKILL", pid)
    pid = spawn_process(params[:new])
  end
  pid ||= spawn_process
  "PID is #{pid}"
end

def spawn_process(host="localhost")
  Process.spawn("em-proxy -l 8080 -r #{host}:3000 -v")
end
