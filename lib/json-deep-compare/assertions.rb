module JsonDeepCompare
  module Assertions
    def assert_json_equal(expected, actual, exclusions = nil)
      comparison = DocumentComparison.new(expected, actual, exclusions: exclusions)
      unless comparison.equal?
        fail comparison.difference_messages
      end
    end
  end
end
