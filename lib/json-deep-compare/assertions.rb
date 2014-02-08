module JsonDeepCompare
  module Assertions
    def assert_json_equal(expected, actual, options = {})
      comparison = DocumentComparison.new(expected, actual, options)
      unless comparison.equal?
        fail comparison.difference_messages
      end
    end
  end
end
