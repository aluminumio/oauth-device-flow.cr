module OAuth::DeviceFlow
  class NetrcStore < Store
    def initialize(@machine : String, @path : String = File.expand_path("~/.netrc", home: true))
    end

    def load : Token?
      return nil unless File.exists?(@path)
      block = find_block(File.read(@path))
      return nil unless block
      access = block["password"]?
      return nil unless access
      account = block["account"]? || ""
      parts = account.split(":", 3)
      refresh = parts[0]?.try { |s| s.empty? ? nil : s }
      expires_at = Time.unix((parts[1]? || "0").to_i64? || 0_i64)
      scope = parts[2]?.try { |s| s.empty? ? nil : s }
      Token.new(
        access_token: access,
        expires_at: expires_at,
        refresh_token: refresh,
        scope: scope,
      )
    end

    def save(token : Token) : Nil
      others = strip_block(File.exists?(@path) ? File.read(@path) : "")
      block = build_block(token)
      File.write(@path, others.empty? ? block : "#{others.rstrip}\n\n#{block}")
      File.chmod(@path, 0o600) rescue nil
    end

    def clear : Nil
      return unless File.exists?(@path)
      remaining = strip_block(File.read(@path))
      File.write(@path, remaining)
    end

    private def find_block(contents : String) : Hash(String, String)?
      in_block = false
      block = Hash(String, String).new
      contents.each_line do |line|
        stripped = line.strip
        next if stripped.empty?
        if stripped.starts_with?("machine ")
          if in_block
            return block
          end
          if stripped == "machine #{@machine}"
            in_block = true
          end
          next
        end
        next unless in_block
        key, _, value = stripped.partition(' ')
        block[key] = value.strip
      end
      in_block ? block : nil
    end

    private def strip_block(contents : String) : String
      out = String.build do |io|
        skipping = false
        contents.each_line(chomp: false) do |line|
          stripped = line.strip
          if stripped.starts_with?("machine ")
            skipping = (stripped == "machine #{@machine}")
            io << line unless skipping
          elsif skipping
            # drop indented continuation lines belonging to our machine
          else
            io << line
          end
        end
      end
      out
    end

    private def build_block(token : Token) : String
      account = "#{token.refresh_token || ""}:#{token.expires_at.to_unix}:#{token.scope || ""}"
      String.build do |io|
        io << "machine " << @machine << "\n"
        io << "  login oauth\n"
        io << "  password " << token.access_token << "\n"
        io << "  account " << account << "\n"
      end
    end
  end
end
