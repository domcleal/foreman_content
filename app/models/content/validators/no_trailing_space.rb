module  Content
  module Validators
    class NoTrailingSpace < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        NoTrailingSpaceValidator.validate_trailing_space(record, attribute, value)
      end

      def self.validate_trailing_space(record, attribute, value)
        if value
          record.errors[attribute] << _("must not contain leading or trailing white spaces.") unless value.strip == value
        end
      end
    end
  end
end