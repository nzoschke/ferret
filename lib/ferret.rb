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

$log_prefix       ||= { app: ENV["TARGET"], xid: ENV["XID"] }
$logdevs          ||= [$stdout, IO.popen("logger", "w")]

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

def bash(opts={})
  opts.rmerge!(name: "bash", retry: 1, pattern: nil, status: 0, stdin: "false", timeout: 180)

  begin
    Timeout.timeout(opts[:timeout]) do
      opts[:retry].times do |i|
        start = Time.now
        log fn: opts[:name], i: i, at: :enter

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
          log fn: opts[:name], i: i, status: status, measure: "#{ENV["TARGET"]}.#{opts[:name]}.success"
          log fn: opts[:name], i: i, val: 100, measure: "#{ENV["TARGET"]}.#{opts[:name]}.uptime"
          log fn: opts[:name], i: i, at: :return, val: Time.now - start, measure: "#{ENV["TARGET"]}.#{opts[:name]}.time"
          return success # break out of retry loop
        else
          out.each_line { |l| log fn: opts[:name], i: i, at: :failure, out: "'#{l.strip}'" }
          # only measure last failure
          if i == opts[:retry] - 1
            log fn: opts[:name], i: i, status: status, measure: "#{ENV["TARGET"]}.#{opts[:name]}.failure"
            log fn: opts[:name], i: i, val: 0, measure: "#{ENV["TARGET"]}.#{opts[:name]}.uptime"
          else
            log fn: opts[:name], i: i, status: status
          end
          log fn: opts[:name], i: i, at: :return, val: Time.now - start
        end
      end

      exit(1)
    end
  rescue Timeout::Error
    log fn: opts[:name], at: :timeout, val: opts[:timeout]
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
