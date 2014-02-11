module JsonDeepCompare
  class DocumentComparison
    def initialize(lval, rval, options = {})
      if exclusions = options[:exclusions]
        options[:exclusions] = [exclusions] unless exclusions.is_a?(Array)
      else
        options[:exclusions] = []
      end
      if substitute_with = options[:substitute_with]
        options[:substitutions] = 
          SubstitutionsBuilder.new(substitute_with).result
      end
      @root_comparisons = []
      @root_comparisons << NodeComparison.new(
        lval, rval, ":root", options.merge(direction: :left)
      )
      @root_comparisons << NodeComparison.new(
        rval, lval, ":root", options.merge(direction: :right)
      )
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

    class SubstitutionsBuilder
      attr_reader :result

      def initialize(proc)
        @proc = proc
        @result = {}
        root = Node.new(":root")
        proc.call root
        root.rules.each do |rule|
          @result[rule.selector] = rule.value
        end
      end

      class Node
        def initialize(selector)
          @selector = selector
          @sub_nodes = []
        end

        def method_missing(meth, *args, &block)
          if block_given?
            if args.size == 1
              sub_node = Node.new(
                @selector + " > .#{meth} :nth-child(#{args.first})"
              )
            else
              sub_node = Node.new(@selector + " > .#{meth}")
            end
            yield sub_node
          elsif args.size == 2
            sub_node = Node.new(
              @selector + " > .#{meth} :nth-child(#{args.first})"
            )
            sub_node.value = args.last
          else
            sub_node = Node.new(@selector + " > .#{meth}")
            sub_node.value = args.first
          end
          @sub_nodes << sub_node
        end

        def rules
          @sub_nodes.map { |sn| sn.rules }.flatten.concat([@rule]).compact
        end

        def value=(v)
          @rule = Rule.new(@selector, v)
        end
      end

      Rule = Struct.new(:selector, :value)
    end
  end
end
