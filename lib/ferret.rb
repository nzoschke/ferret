require "fileutils"
require "securerandom"
require "timeout"
require "tmpdir"

ENV["APP"]        ||= "ferret"
ENV["FERRET_DIR"] ||= File.expand_path(File.join(__FILE__, "..", ".."))
ENV["FILENAME"]   ||= File.basename($0, File.extname($0)) # e.g. git/push
ENV["ORG"]        ||= "ferret"
ENV["TEMP_DIR"]   ||= Dir.mktmpdir
ENV["XID"]        ||= SecureRandom.hex(4)

$log_prefix       ||= { app: "#{ENV["ORG"]}.#{ENV["APP"]}", xid: ENV["XID"] }
$logdevs          ||= [$stdout, IO.popen("logger", "w")]

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

def test(opts={}, &blk)
  opts.rmerge!(name: "test", retry: 1, pattern: nil, status: 0, timeout: 180)
  source = "#{ENV["FILENAME"]}.#{opts[:name]}".gsub(/\//, ".").gsub(/_/, "-")

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
          status = yield ? 0 : 1
          out = ""
        end

        success   = true
        success &&= status == opts[:status]   if opts[:status]
        success &&= !!(out =~ opts[:pattern]) if opts[:pattern]

        if success
          log source: source, i: i, status: status, measure: "success"
          log source: source, i: i, val: 100, measure: "uptime"
          log source: source, i: i, at: :return, val: "%0.4f" % (Time.now - start), measure: "time"
          return success # break out of retry loop
        else
          out.each_line { |l| log source: source, i: i, at: :failure, out: "'#{l.strip}'" }

          # only measure last failure
          if i == opts[:retry] - 1
            log source: source, i: i, status: status, measure: "failure"
            log source: source, i: i, val: 0, measure: "uptime"
          else
            log source: source, i: i, status: status
          end

          log source: source, i: i, at: :return, val: "%0.4f" % (Time.now - start)
        end
      end

      exit(1)
    end
  rescue Timeout::Error
    log source: source, at: :timeout, val: opts[:timeout]
    if opts[:pid]
      Process.kill("INT", -Process.getpgid(opts[:pid]))
      Process.wait(opts[:pid])
    end
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
