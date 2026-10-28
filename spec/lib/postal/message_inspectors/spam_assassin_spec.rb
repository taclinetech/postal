# frozen_string_literal: true

require "rails_helper"

module Postal
  module MessageInspectors

    RSpec.describe SpamAssassin do
      let(:config) { double(host: "spamd.example.com", port: 783) }
      let(:message) { double(raw_message: "Subject: Test\r\n\r\nHello\r\n") }
      let(:inspection) { MessageInspection.new(message, :incoming) }

      subject(:inspector) { described_class.new(config) }

      # Log the way production does: Klogger with its default formatter and no
      # highlighting, written somewhere real so every line gets formatted.
      let(:log) { StringIO.new }

      before do
        allow(Postal).to receive(:logger).and_return(Klogger.new(nil, destination: log, highlight: false))
      end

      describe "#inspect_message" do
        context "when spamd can't be reached" do
          before do
            allow(TCPSocket).to receive(:new).and_raise(Errno::ECONNREFUSED)
          end

          it "adds an ERROR spam check instead of raising" do
            expect { inspector.inspect_message(inspection) }.not_to raise_error
            expect(inspection.spam_checks.map(&:code)).to eq ["ERROR"]
          end
        end
      end
    end

  end
end
