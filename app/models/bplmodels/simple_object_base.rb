module Bplmodels
  class SimpleObjectBase < Bplmodels::ObjectBase

    ## Produce a unique filename that doesn't already exist.
    def temp_filename(basename, tmpdir='/tmp')
      n = 0
      begin
        tmpname = File.join(tmpdir, sprintf('%s%d.%d', basename, $$, n))
        lock = tmpname + '.lock'
        n += 1
      end while File.exist?(tmpname)
      tmpname
    end

    #def save
      #super()
      #super
    #end

    def to_solr(doc = {} )
      doc = super(doc)
      doc

    end

  end
end
