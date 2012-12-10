require "fileutils"
require "securerandom"
require "timeout"
require "tmpdir"

ENV["FERRET_DIR"] ||= File.expand_path(File.join(__FILE__, "..", ".."))
ENV["ORG"]        ||= "ferret"
ENV["NAME"]       ||= File.basename($0, File.extname($0)) # e.g. git_push
ENV["TARGET"]     ||= "#{ENV["APP"]}.#{ENV["NAME"]}"      # e.g. ferret-noah.git-push
ENV["TARGET_APP"] ||= ENV["TARGET"].gsub(/[\._]/, '-')    # e.g. ferret-noah-git-push
ENV["TEMP_DIR"]   ||= Dir.mktmpdir
ENV["XID"]        ||= SecureRandom.hex(4)
ENV["FREQ"]       ||= "10"
$log_prefix       ||= { app: ENV["TARGET"], xid: ENV["XID"] }
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

def run(time)
  if time == :forever
    $threads.each(&:join)
  else
    #should be 
    #sleep time 
    #but for some reason this code path is being hit even when forever is passed
    $threads.each(&:join)
  end
end

def uses_app(path)
  ENV["APP_DIR"] = path
  bash(retry: 2, name: :setup, stdin: <<-'EOSTDIN')
  heroku info --app $TARGET_APP || {
    heroku create $TARGET_APP                                            \
    && heroku plugins:install https://github.com/heroku/manager-cli.git  \
    && heroku manager:transfer --app $TARGET_APP --to $ORG               \
    && cd $APP_DIR                                                       \
    && bundle install                                                    \
    && heroku build -r $TARGET_APP $APP_DIR                              \
    && heroku scale web=1 --app $TARGET_APP                              \
    && cd $FERRET_DIR
  }
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
      sleep interval * Integer(ENV["FREQ"])
    }
  end
end

def run_every_time(&block)
  $threads << Thread.new do
    loop{
      $lock.synchronize {
        block.call
      }
      sleep Integer(ENV["FREQ"])
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

        success   = true
        success &&= status == opts[:status]   if opts[:status]
        success &&= !!(out =~ opts[:pattern]) if opts[:pattern]

        if success
          log source: "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, status: status, measure: "success"
          log source:  "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, val: 100, measure: "uptime"
          log source:  "#{ENV["NAME"]}.#{opts[:name]}", app: ENV["APP"], i: i, at: :return, val: Time.now - start, measure: "time"
          return success # break out of retry loop
        else
          out.each_line { |l| log source:  "#{ENV["NAME"]}.#{opts[:name]}", i: i, at: :failure, out: "'#{l.strip}'" }
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

      exit(1)
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
