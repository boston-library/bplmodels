require "bplmodels/engine"
require "bplmodels/datastream_input_funcs"
require "bplmodels/constants"
require "timeliness"

# add some formats to Timeliness gem for better parsing
Timeliness.add_formats(:date, 'm-d-yy', :before => 'd-m-yy')
Timeliness.add_formats(:date, 'mmm[\.]? d[a-z]?[a-z]?[,]? yyyy')
Timeliness.add_formats(:date, 'yyyy mmm d')

module Bplmodels
end
