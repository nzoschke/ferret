require "fileutils"
require "securerandom"
require "timeout"
require "tmpdir"
require "redis"
require "statsample"

$redis                      = Redis.connect :url => ENV["OPENREDIS_URL"]


$name = ENV["NAME"]               ||= File.basename($0, File.extname($0)) # e.g. git_push
ENV["APP"]                ||= "ferret"
ENV["FERRET_DIR"]         ||= File.expand_path(File.join(__FILE__, "..", ".."))
ENV["ORG"]                ||= "ferret-dev"
ENV["SCRIPT"]             ||= File.expand_path($0) # $FERRET_DIR/tests/git/push or $FERRET_DIR/tests/unit/test_ferret.rb
ENV["TEMP_DIR"]           ||= Dir.mktmpdir
ENV["FREQ"].to_i          || 30.to_s
ENV["INTERVAL"]           ||= 240.to_s #how long to track for in seconds when doing math (time-series window)
Thread.current[:xid]        = SecureRandom.hex(4)
ENV["SERVICE_LOG_NAME"]   ||= "#{ENV["APP"]}.#{ENV["NAME"]}" # e.g. ferret-noah.git-push #slave app name
ENV["SERVICE_APP_NAME"]   ||= ENV["USER"] + "-" + ENV["SERVICE_LOG_NAME"].gsub(/[\._]/, '-') # e.g. ferret-noah-git-push #used for deploying slave app

$log_prefix               ||= { app: "#{ENV["APP"]}"}
$logdevs                  ||= [$stdout, IO.popen("logger", "w")]
$threads                    = []
$lock                       = Mutex.new

if !$redis.hexists($name,"app")
  $redis.hset($name,"app",ENV["APP"])
  $redis.hset($name,"freq",ENV["FREQ"].to_i)
  $redis.hset($name, "status","starting")
  $redis.hset($name, "interval", ENV["INTERVAL"].to_i)

end
$freq = $redis.hget($name,"freq").to_i
$interval = $redis.hget($name, "interval").to_i

trap("EXIT") do
  log fn: :exit
  $logdevs.each { |dev| next if !dev.pid; Process.kill("INT", dev.pid); Process.wait(dev.pid) }
  FileUtils.rm_rf ENV["TEMP_DIR"]
end


class Hash
  def rmerge!(h)
    replace(h.merge(self))
  end
end

def dostats()
  lasttime  = Thread.current[:lasttime] || 0
  drop      = (Time.now.to_i - lasttime)/$interval
  uptimesa   = Thread.current[:uptimes]
  timesa     = Thread.current[:times]
  uaveragesa = Thread.current[:uavarages]
  taveragesa = Thread.current[:tavarages]
  if drop > 0
    uptimesa.slice!(0..drop)
    timesa.slice!(0..drop)
    uaveragesa.slice!(0..drop)
    taveragesa.slice!(0..drop)
  end


  uaverages = uaveragesa.to_vector(:scale)
  taverages = taveragesa.to_vector(:scale)
  uptimes   = uptimesa.to_vector(:scale)
  times     = timesa.to_vector(:scale)

  uaveragesa << times.mean
  taveragesa << uptimes.mean

  $redis.hset($name, "#{Thread.current[:name]}.uptime.mean", uptimes.mean)
  $redis.hset($name, "#{Thread.current[:name]}.uptime.min", uptimes.min)
  $redis.hset($name, "#{Thread.current[:name]}.uptime.max", uptimes.max)
  $redis.hset($name, "#{Thread.current[:name]}.uptime.last", uptimesa.last)
  $redis.hset($name, "#{Thread.current[:name]}.uptime.average_variance", uaverages.variance)
  $redis.hset($name, "#{Thread.current[:name]}.uptime.variance", uptimes.variance)

  $redis.hset($name, "#{Thread.current[:name]}.time.mean", times.mean)
  $redis.hset($name, "#{Thread.current[:name]}.time.min", times.min)
  $redis.hset($name, "#{Thread.current[:name]}.time.max", times.max)
  $redis.hset($name, "#{Thread.current[:name]}.time.last", timesa.last)
  $redis.hset($name, "#{Thread.current[:name]}.time.variance", times.variance)
  $redis.hset($name, "#{Thread.current[:name]}.time.average_variance", taverages.variance)
  Thread.current[:lasttime] = Time.now.to_i
end

def run(opts={})
  if opts[:forever]
    $threads.each(&:join)
  else
    sleep opts[:time]
  end
end

def test_name(name)
  ENV["NAME"] = name
end

def test_freq(freq)
  ENV["FREQ"] = freq.to_s
end

def uses_app(opts={})
  ENV["APP_DIR"] = opts[:path]
  ENV["STACK"] = opts[:stack] || "cedar"

  log fn: :uses_app, name: ENV["SERVICE_APP_NAME"], at: :enter

  bash(retry: 2, name: :create, stdin: <<-'EOSTDIN')
    heroku apps:delete $SERVICE_APP_NAME --confirm $SERVICE_APP_NAME           
    heroku apps:create $SERVICE_APP_NAME -s $STACK                    \
    && heroku manager:transfer --app $SERVICE_APP_NAME --to $ORG
  EOSTDIN

  return if opts[:empty]

  bash(retry: 2, name: :release, stdin: <<-'EOSTDIN')
    cd $APP_DIR                                                       \
    && heroku build -r $SERVICE_APP_NAME                              \
    && heroku scale web=1 --app $SERVICE_APP_NAME                     \
    && cd $FERRET_DIR
  EOSTDIN
end

def run_interval(interval, &block)
  $threads << Thread.new do
    loop {
      $lock.synchronize {
        Thread.current[:xid] = SecureRandom.hex(4)
        block.call
      }
      sleep interval * ENV["FREQ"].to_i
    }
  end
end

def run_every_time(&block)
  $threads << Thread.new do
    loop{
      $lock.synchronize {
        Thread.current[:xid] = SecureRandom.hex(4)
        block.call
      }
      sleep ENV["FREQ"].to_i
    }
  end
end

def bash(opts={})

  opts[:bash] = opts[:stdin]
  test(opts)
end

def test(opts={}, &blk) 
  
  opts.rmerge!(name: "test", retry: 1, pattern: nil, status: 0, timeout: 180)

  Thread.current[:times]     ||= Array.new
  Thread.current[:uptimes]   ||= Array.new
  Thread.current[:uavarages] ||= Array.new
  Thread.current[:tavarages] ||= Array.new 
  Thread.current[:failcount] ||= 0
  
  times = Thread.current[:times]
  uptimes = Thread.current[:uptimes]
  script = ENV["SCRIPT"].chomp(File.extname(ENV["SCRIPT"]))           # strip extension
  script = script.split("/").last(2).join("/")                        # e.g. git/push or unit/test_ferret
  ENV["TARGET_APP"] = "#{ENV["APP"]}-#{script}".gsub(/[\/_]/, "-")    # e.g. ferret-git-push or ferret-unit-test-ferret
  source = "\"#{script}.#{opts[:name]}\"".gsub(/\//, ".").gsub(/_/, "-")  # e.g. git.push.test
  Thread.current[:name] = opts[:name]
  begin
    Timeout.timeout(opts[:timeout]) do
      opts[:retry].times do |i|
        start = Time.now
        log source: source, i: i, at: :enter

        if opts[:bash]
          r0, w0 = IO.pipe
          r1, w1 = IO.pipe

          opts[:pid] = Process.spawn("bash", "--noprofile", "-s", chdir: ENV["TEMP_DIR"], pgroup: 0, in: r0, out: w1, err: w1)

          w0.write(opts[:bash])
          r0.close
          w0.close

          Process.wait(opts[:pid])
          w1.close

          status = $?.exitstatus
          out    = r1.read
        else
          status = (yield source) ? 0 : 1
          out = ""
        end

        success   = true
        success &&= status == opts[:status]   if opts[:status]
        success &&= !!(out =~ opts[:pattern]) if opts[:pattern]

        if success
          Thread.current[:failcount] = 0
          log source: source, i: i, status: status, measure: "success"
          log source: source, i: i, val: 100, measure: "uptime"
          log source: source, i: i, at: :return, val: "%0.4f" % (Time.now - start), measure: "time"
          uptimes << 100
          times << (Time.now - start)
          $redis.hset($name,"#{Thread.current[:name]}.status","up")
          $redis.hset($name,"status","up")
          return success # break out of retry loop
        else
          $redis.hset($name, "#{Thread.current[:name]}.status" ,"yellow")
          $redis.hset($name, "status", "yellow" )
          out.each_line { |l| log source: source, i: i, at: :failure, out: "'#{l.strip}'" }

          end
          # only measure last failure
          if i == opts[:retry] - 1
            log source: source, i: i, status: status, measure: "failure"
            log source: source, i: i, val: 0, measure: "uptime"
            uptimes << 0
            times << (Time.now - start)
            Thread.current[:failcount] = Thread.current[:failcount]+1
          if Thread.current[:failcount] > 5
            $redis.hset($name,"#{Thread.current[:name]}.status","down")
            $redis.hset($name,"status","down") 
          else
            log source: source, i: i, status: status
          end
          log source: source, i: i, at: :return, val: "%0.4f" % (Time.now - start)
        end
      end
      dostats
    end
  rescue Timeout::Error
    log source: source, at: :timeout, val: opts[:timeout]
    if opts[:pid]
      Process.kill("INT", -Process.getpgid(opts[:pid]))
      Process.wait(opts[:pid])
    end
  end
end

def log(data)
  data.rmerge! xid: Thread.current[:xid]
  data.rmerge! $log_prefix 
  
  data.reduce(out=String.new) do |s, tup|
    s << [tup.first, tup.last].join("=") << " "
  end

  $logdevs.each { |l| l << out.strip + "\n" }
end
