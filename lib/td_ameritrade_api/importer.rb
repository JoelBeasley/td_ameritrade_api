module TDAmeritradeAPI
  class Importer

    ENTITIES = {
        'SEC' => Security,
        'PRI' => Price,
        'POS' => Position,
        'TRD' => DemographicFile,
        'TRN' => Transaction,
        'INI' => InitialPosition,
        'CBL' => CostBasisReconciliation
    }

    attr_reader :file

    def initialize(file)
      @file = file
    end

    def run
      adapter.import(file)
    end

    def adapter
      ADAPTERS[File.extname(file).gsub('.', '').capitalize]
    end

  end
end