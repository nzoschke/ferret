require "fileutils"
require "securerandom"
require "timeout"
require "tmpdir"

ENV["ORG"]        ||= "ferret"
ENV["TARGET_APP"] ||= "#{ENV["ORG"]}-#{File.basename($0, File.extname($0)).gsub(/_/, '-')}" # e.g. ferret-git-push
ENV["TEMP_DIR"]   ||= Dir.mktmpdir
ENV["XID"]        ||= SecureRandom.hex(4)

$log_prefix       ||= { app: ENV["TARGET_APP"], xid: ENV["XID"] }
$logdev           ||= $stdout
$logger           ||= IO.popen("logger", "w")

trap("EXIT") do
  log fn: :exit
  if $logger.pid
    Process.kill("KILL", $logger.pid)
    Process.wait($logger.pid)
  end
  FileUtils.rm_rf ENV["TEMP_DIR"]
end

class Hash
  def rmerge!(h)
    replace(h.merge(self))
  end
end

def bash(opts={})
  opts.rmerge!(name: "bash", retry: 1, status: 0, stdin: "false", timeout: 180)

  begin
    Timeout.timeout(opts[:timeout]) do
      success = nil

      opts[:retry].times do |i|
        log(fn: opts[:name], i: i, measure: true) do

          r0, w0 = IO.pipe
          r1, w1 = IO.pipe

          pid = Process.spawn(["bash", "-s"], chdir: ENV["TEMP_DIR"], in: r0, out: w1, err: w1)

          w0.write(opts[:stdin])
          r0.close; w0.close

          Process.wait(pid)
          w1.close

          if $?.to_i == opts[:status]
            log fn: opts[:name], i: i, at: "#{opts[:name]}-success", status: $?.to_i, measure: true
            success = true
          else
            log fn: opts[:name], i: i, at: "#{opts[:name]}-error",   status: $?.to_i, measure: true
            r1.each_line { |l| log fn: opts[:name], i: i, at: :error, out: "'#{l.strip}'" }
            success = false
          end
        end && break # break out of loop when successful
      end

      success || exit(1)
    end
  rescue Timeout::Error => e
    log fn: opts[:name], at: :timeout
    exit(2)
  end
end

def log(data)
  data.rmerge! $log_prefix

  if block_given?
    m = data.delete(:measure)
    data.merge!(at: :enter)
    log data

    start = Time.now
    result = yield

    data.merge!(at: :return, elapsed: Time.now - start)
    data.merge!(measure: m) if m && result # only measure if block doesn't fail
    log data

    return result
  end

  data.reduce(out=String.new) do |s, tup|
    s << [tup.first, tup.last].join("=") << " "
  end

  [$logdev, $logger].each { |l| l << out.strip + "\n" }
end
