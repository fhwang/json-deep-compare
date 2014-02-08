module JsonDeepCompare
  class DocumentComparison
    def initialize(lval, rval, options = {})
      if exclusions = options[:exclusions]
        options[:exclusions] = [exclusions] unless exclusions.is_a?(Array)
      else
        options[:exclusions] = []
      end
      @root_comparisons = []
      @root_comparisons << NodeComparison.new(lval, rval, ":root", options)
      @root_comparisons << NodeComparison.new(rval, lval, ":root", options)
    end

    def difference_messages
      ldiffs = @root_comparisons.first.differences
      rdiffs = @root_comparisons.last.differences
      differences = ldiffs.dup
      ldiff_selectors = ldiffs.map { |ldiff| ldiff.selector }
      rdiffs.each do |rdiff|
        unless ldiff_selectors.include?(rdiff.selector)
          differences << rdiff.reverse
        end
      end
      differences = differences.sort_by &:selector
      differences.map(&:message).join("\n")
    end

    def equal?
      @root_comparisons.all?(&:equal?)
    end
  end
end
