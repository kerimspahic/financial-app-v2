class InputComponent < ApplicationComponent
  def initialize(form:, field:, label: nil, type: :text, hint: nil, required: false,
                 collection: nil, include_blank: nil, **options)
    @form = form
    @field = field
    @label = label
    @type = type.to_sym
    @hint = hint
    @required = required
    @collection = collection
    @include_blank = include_blank
    @options = options
  end

  def label_text
    @label || @field.to_s.humanize
  end

  def has_error?
    @form.object&.errors&.include?(@field)
  end

  def error_messages
    @form.object&.errors&.full_messages_for(@field)&.join(", ")
  end

  def input_classes
    base = "block w-full rounded-xl border px-4 py-2.5 text-sm glass text-text-primary " \
           "placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-offset-0 transition-all duration-200"
    if has_error?
      "#{base} border-danger-500 focus:ring-danger-500"
    else
      "#{base} border-input-border focus:ring-input-focus focus:border-transparent"
    end
  end
end
