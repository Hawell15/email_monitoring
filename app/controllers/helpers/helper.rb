module Helper
  def compress(hash)
    hash.reject { |_key, value| value.nil? || value.empty? }
  end

  def normalize_string(string)
    return "" if string.nil?
    string.gsub(/[−–]/, "-").squeeze(' ').strip
  end

  def parse_description(string)
    normalize_string(string.gsub(/[\s]/, ' '))
  end
end
