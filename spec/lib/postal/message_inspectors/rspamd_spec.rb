# frozen_string_literal: true

require "rails_helper"

module Postal
  module MessageInspectors

    RSpec.describe Rspamd do
      let(:config) { double(host: "rspamd.example.com", port: 11_333, ssl: false, password: nil, flags: nil) }
      let(:message) do
        double(raw_message: "Subject: Test\r\n\r\nHello\r\n",
               rcpt_to: "rcpt@example.com",
               mail_from: "sender@example.com",
               token: "abc123")
      end
      let(:inspection) { MessageInspection.new(message, :incoming) }

      subject(:inspector) { described_class.new(config) }

      # Log the way production does: Klogger with its default formatter and no
      # highlighting, written somewhere real so every line gets formatted.
      let(:log) { StringIO.new }

      before do
        allow(Postal).to receive(:logger).and_return(Klogger.new(nil, destination: log, highlight: false))
      end

      describe "#inspect_message" do
        context "when rspamd can't be reached" do
          before do
            stub_request(:post, "http://rspamd.example.com:11333/checkv2").to_raise(Errno::ECONNREFUSED)
          end

          it "adds an ERROR spam check instead of raising" do
            expect { inspector.inspect_message(inspection) }.not_to raise_error
            expect(inspection.spam_checks.map(&:code)).to eq ["ERROR"]
            expect(inspection.spam_score).to eq 0
            expect(log.string).to include("Error talking to rspamd: Errno::ECONNREFUSED")
          end
        end
      end
    end

  end
end
