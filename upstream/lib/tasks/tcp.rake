namespace :tcp do |ns|
  task :list do
    puts 'All tasks:'
    puts ns.tasks
  end

  task :generate_p0f_map do
    p0f_archive_path = "tmp/p0f-latest.tgz"
    p0f_map_path = "tmp/p0f.fp"
    fingerbank_p0f_map_path = "db/package/p0f-fingerbank.fp"
    Rake::Task["tcp:download_p0f"].invoke(p0f_archive_path)
    Rake::Task["tcp:extract_p0f_map"].invoke(p0f_archive_path,p0f_map_path)
    Rake::Task["tcp:convert_p0f_map"].invoke(p0f_map_path,fingerbank_p0f_map_path)
  end

  task :download_p0f, [:destination] do |t, args|
    Net::HTTP.start("lcamtuf.coredump.cx") do |http|
      resp = http.get("/p0f3/releases/p0f-latest.tgz")
      open(args[:destination], "wb") do |file|
          file.write(resp.body)
          puts "Downloaded p0f latest archive"
      end
    end
  end

  task :extract_p0f_map, [:archive, :destination] do |t, args|
    Dir.mktmpdir { |dir|
      `tar -xvf #{args[:archive]} -C #{dir}`
      p0f_dir = nil
      Dir.entries(dir).select { |f| 
        if f !~ /^\./
          p0f_dir = f
        end
      }
      p0f_dir = "#{dir}/#{p0f_dir}"
      `cp -fp #{p0f_dir}/p0f.fp #{args[:destination]}`
      puts "Copied p0f map to #{args[:destination]}"
    }
    
  end

  task :convert_p0f_map, [:source, :destination] do |t, args|
    REPLACE_MAP = {
      'Linux:(Android)' => '202:nil',
      'Linux:Linux:2.4-2.6' => '5:2.4/-/2.6',
      'Linux:Linux:3.x' => '5:3',
      'Linux:Linux:2.4.x' => '5:2.4',
      'Linux:Linux:2.6.x' => '5:2.6',
      /Linux:.*/ => '5:nil',
      'Windows:XP' => '26:nil',
      'Windows:7 or 8' => '1:7/8',
      'Windows:7' => '36:7',
      'Windows:7 (Websense crawler)' => '36:7',
      'Windows:NT kernel 5.x' => '7534:nil',
      'Windows:NT kernel 6.x' => '7536:nil',
      'Windows:NT kernel' => '1:nil',
      'Mac OS X:' => '38:nil',
      'Mac OS X:10.x' => '38:nil',
      'MacOS X:10.9 or newer (sometimes iPhone or iPad)' => '38:10.9+',
      'iOS:iPhone or iPad' => '193:nil',
      'FreeBSD:9.x or newer' => '230:9+',
      'FreeBSD:8.x' => '230:8',
      'FreeBSD:8.x-9.x' => '230:8/9',
      'FreeBSD:9.x' => '230:9',
      'FreeBSD:' => '230:nil',
      'OpenBSD:3.x' => '229:3',
      'OpenBSD:4.x-5.x' => '229:4/5',
      'OpenBSD:5.x' => '229:4/5',
      /Solaris:([0-9.]+)/ => '19:10',
      'OpenVMS:8.x' => '7539:8',
      'OpenVMS:7.x' => '7539:7',
      'NeXTSTEP:' => '7538:nil',
      'Blackberry:' => '192:nil',
      'Nintendo:3DS' => '6935:nil',
      'Nintendo:Wii' => '138:nil',
      'HP-UX:11.x' => '7540:11',
      'Tru64:4.x' => '7541:4',
      'NMap:SYN scan' => 'nil:nil',
      'NMap:OS detection' => 'nil:nil',
      'p0f:sendsyn utility' => 'nil:nil',
      'BaiduSpider:' => 'nil:nil',
    }

    replace_map = {}
    REPLACE_MAP.each do |search,replace|
      unless search.is_a? Regexp
        search = /#{Regexp.escape(search)}$/
      end
      replace_map[search] = replace
    end

    starting_points = ["[tcp:request]","[tcp:response]"]
    ending_point = /^\[.*\]$/

    lines = File.open('tmp/p0f-3.08b/p0f.fp').read
    lines.gsub!(/\r\n?/, "\n")

    tcp_lines = []
    failed = []
    read_lines = false

    lines.each_line do |line|
      line.gsub!(/\n?/, "")
      if starting_points.include?(line)
        read_lines = true
      elsif line =~ ending_point
        read_lines = false
      end

      if read_lines && !line.empty? && !(line =~ /^;/)
        tcp_lines << line
      end
    end

    tcp_lines.each do |line|
      if line =~ /^label /
        found = false
        replace_map.each do |search,replace|
          if line.gsub!(search,replace)
            found = true
            break
          end
        end
        if !found
          failed << line
        end
      end
    end


    File.open(args[:destination], 'w') { |file| 
      unless failed.empty?
        file.write ";=====================\n"
        file.write ";FAILED for : \n"
        file.write ";=====================\n"
        failed = failed.map {|o| ";#{o}"}
        file.write failed.join("\n")
      end

      file.write "classes = win,unix,other\n"
      file.write tcp_lines.join("\n")

      puts "Completed conversion of p0f map into #{args[:destination]}"
    }

  end
end
