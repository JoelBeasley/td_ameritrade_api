module TDAmeritradeAPI
  class Importer

    ENTITIES = {
        'SEC' => Security,
        'PRI' => Price,
        'POS' => Position,
        'TRD' => Demographic,
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
      ENTITIES[file_name.split('.').last.upcase]
    end

  end
end