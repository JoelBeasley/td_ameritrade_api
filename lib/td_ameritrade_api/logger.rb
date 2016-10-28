module TDAmeritradeAPI
  class << self
    attr_writer :reader

    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.progname = self.name
      end
    end
  end
end