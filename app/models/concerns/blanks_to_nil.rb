# The spec is emphatic that almost nothing is required and that the app never
# nags about a blank field (UX-10, and the three forgiveness rules in section 1).
# HTML forms post "" for an untouched optional select or input, which then
# trips the NULL-or-enum check constraints. Treat a blank as "not answered".
module BlanksToNil
  extend ActiveSupport::Concern

  class_methods do
    def blanks_to_nil(*attributes)
      before_validation do
        attributes.each do |attribute|
          value = self[attribute]
          self[attribute] = nil if value.is_a?(String) && value.strip.empty?
        end
      end
    end
  end
end
