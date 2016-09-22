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

    attr_reader :file, :file_name

    def initialize(file, file_name = nil)
      @file = file
      @file_name = file_name || File.basename(file)
    end

    def run
      adapter.import(file, file_name)
    end

    def adapter
      ENTITIES[File.extname(file).gsub('.', '').upcase]
    end

  end
end