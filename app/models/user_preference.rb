class UserPreference < ApplicationRecord
  belongs_to :user

  THEME_MODES = %w[light dark system].freeze
  COLOR_MODES = %w[green blue purple rose amber cyan].freeze
  STYLE_MODES = %w[modern win95 winxp vista win7].freeze
  PER_PAGE_OPTIONS = [ 10, 25, 50, 100 ].freeze

  validates :theme_mode, presence: true, inclusion: { in: THEME_MODES }
  validates :color_mode, presence: true, inclusion: { in: COLOR_MODES }
  validates :style_mode, presence: true, inclusion: { in: STYLE_MODES }
  validates :per_page, presence: true, inclusion: { in: PER_PAGE_OPTIONS }
end
