require "fileutils"
require "securerandom"
require "timeout"
require "tmpdir"

ENV["FERRET_DIR"] ||= File.expand_path(File.join(__FILE__, "..", ".."))
ENV["ORG"]        ||= "ferret-dev"
ENV["NAME"]       ||= File.basename($0, File.extname($0)) # e.g. git_push
ENV["SERVICE_LOG_NAME"]     ||= "#{ENV["APP_PREFIX"]}.#{ENV["NAME"]}"      # e.g. ferret-noah.git-push #slave app name
ENV["SERVICE_APP_NAME"] ||= ENV["SERVICE_LOG_NAME"].gsub(/[\._]/, '-')    # e.g. ferret-noah-git-push #used for deploying slave app
ENV["TEMP_DIR"]   ||= Dir.mktmpdir
ENV["XID"]        ||= SecureRandom.hex(4)
ENV["FREQ"]       ||= "10"
$log_prefix       ||= { app: ENV["SERVICE_LOG_NAME"], xid: ENV["XID"] }
$logdevs          ||= [$stdout, IO.popen("logger", "w")]
$threads             = []
$lock                = Mutex.new

trap("EXIT") do
  log fn: :exit
  pids = $logdevs.map { |logdev| logdev.pid }.compact
  $logdevs.each { |dev| next if !dev.pid; Process.kill("INT", dev.pid); Process.wait(dev.pid) }
  FileUtils.rm_rf ENV["TEMP_DIR"]
end

class Hash
  def rmerge!(h)
    replace(h.merge(self))
  end
end

def run(opts={})
  puts opts.inspect
  if opts[:forever]
    $threads.each(&:join)
  else
    #should be 
    #sleep time 
    #but for some reason this code path is being hit even when forever is passed
    sleep opts[:time]
  end
end

def uses_app(path)
  ENV["APP_DIR"] = path
  bash(retry: 2, name: :setup, stdin: <<-'EOSTDIN')
    heroku apps:delete $SERVICE_APP_NAME --confirm $SERVICE_APP_NAME
    heroku apps:create $SERVICE_APP_NAME                                              \
      && heroku plugins:install https://github.com/heroku/manager-cli.git  \
      && heroku manager:transfer --app $SERVICE_APP_NAME --to $ORG               \
      && cd $APP_DIR                                                       \
      && bundle install                                                    \
      && heroku build -r $SERVICE_APP_NAME                                       \
      && heroku scale web=1 --app $SERVICE_APP_NAME                              \
      && cd $FERRET_DIR

EOSTDIN
  #if setup has been defined use that
  #otherwise run basic deploy
end

def run_interval(interval, &block)
  $threads << Thread.new do
    loop {
      $lock.synchronize {
        block.call
      }
      sleep interval * 10
    }
  end
end

def run_every_time(&block)
  $threads << Thread.new do
    loop{
      $lock.synchronize {
        block.call
      }
      sleep 10
    }
  end
end
def bash(opts={})
  opts.rmerge!(name: "bash", retry: 1, pattern: nil, status: 0, stdin: "false", timeout: 180)

  begin

    Timeout.timeout(opts[:timeout]) do
      opts[:retry].times do |i|
        start = Time.now
        log source: ENV["NAME"], app: ENV["APP"],fn: opts[:name], i: i, at: :enter

        r0, w0 = IO.pipe
        r1, w1 = IO.pipe

        opts[:pid] = Process.spawn("bash", "--noprofile", "-s", chdir: ENV["TEMP_DIR"], pgroup: 0, in: r0, out: w1, err: w1)

        w0.write(opts[:stdin])
        r0.close
        w0.close

        Process.wait(opts[:pid])
        w1.close

        status = $?.exitstatus
        out    = r1.read
        puts out
        success   = true
        success &&= status == opts[:status]   if opts[:status]
        success &&= !!(out =~ opts[:pattern]) if opts[:pattern]

        if success
          log source: "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, status: status, measure: "success"
          log source:  "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, val: 100, measure: "uptime"
          log source:  "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, at: :return, val: Time.now - start, measure: "time"
          return success # break out of retry loop
        else
          out.each_line { |l| log source:  "#{ENV["NAME"]}.#{opts[:name]}",app: ENV["APP"],  i: i, at: :failure, out: "'#{l.strip}'" }
          # only measure last failure
          if i == opts[:retry] - 1
            log source:  "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, status: status, measure: "failure"
            log source:  "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, val: 0, measure: "uptime"
          else
            log source:  "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, status: status
          end
          log source: "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, at: :return, val: Time.now - start
        end
      end
    end
  rescue Timeout::Error
    log source:  "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"],at: :timeout, val: opts[:timeout]
    Process.kill("INT", -Process.getpgid(opts[:pid]))
    Process.wait(opts[:pid])
    exit(2)
  end
end

def log(data)
  data.rmerge! $log_prefix

  data.reduce(out=String.new) do |s, tup|
    s << [tup.first, tup.last].join("=") << " "
  end

  $logdevs.each { |l| l << out.strip + "\n" }
end
