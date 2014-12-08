class Logger
  def format_message(severity, timestamp, progname, msg)
    line = ''
    Kernel.caller.each{|entry|
      if (entry.include? Rails.root.to_s)
        line = " #{entry.gsub(Rails.root.to_s,'').gsub(/\/(.+)\:in `(.+)'/, "\\1 -> \\2")}"
        break
      end
    }
    "[#{timestamp.strftime("%Y%m%d.%H:%M:%S")}] #{severity}#{line}: #{msg}\n"
  end
end
