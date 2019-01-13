class MatchScore < ApplicationRecord
  belongs_to :player, foreign_key: "player_id"
  has_one :beatmap

  validates_uniqueness_of :match_id, scope: [:player_id, :beatmap_id]
end
