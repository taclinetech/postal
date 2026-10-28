# frozen_string_literal: true

class ReceivedHeader

  OUR_HOSTNAMES = {
    smtp: Postal::Config.postal.smtp_hostname,
    http: Postal::Config.postal.web_hostname
  }.freeze

  class << self

    def generate(server, helo, ip_address, method)
      our_hostname = OUR_HOSTNAMES[method]
      if our_hostname.nil?
        raise Error, "`method` is invalid (must be one of #{OUR_HOSTNAMES.join(', ')})"
      end

      header = "by #{our_hostname} with #{method.to_s.upcase}; #{Time.now.utc.rfc2822}"

      if server.nil? || server.privacy_mode == false
        hostname = DNSResolver.local.ip_to_hostname(ip_address)
        header = "from #{helo} (#{hostname} [#{ip_address}]) #{header}"
      end

      header
    end

    # Read the sending server's HELO and IP address back out of a Received
    # header that .generate wrote when the message arrived over SMTP.
    #
    # @param header [String] the header's value, without the "Received:" name
    # @return [Hash, nil] :helo and :ip_address, or nil for any other header,
    #   including one written with privacy mode on, which names neither
    def parse(header)
      match = header.to_s.match(/\Afrom (.+?) \(\S* \[([^\]\s]+)\]\) by (\S+) with SMTP;/)
      return nil if match.nil?
      return nil unless match[3] == OUR_HOSTNAMES[:smtp]

      { helo: match[1], ip_address: match[2] }
    end

  end

end
