class StatisticsController < ApplicationController
  def show_matches
    @data = Match.all.map {|match|
      {
        :round_name => match.round_name,
        :winner => match.winner,
        :online_id => match.online_id,
        :red_player => {
          :id => match.player_red.id,
          :name => match.player_red.name,
        },
        :blue_player => {
          :id => match.player_blue.id,
          :name => match.player_blue.name,
        },
        :timestamp => match.match_timestamp.to_time.iso8601,
        :id => match.id,
      }
    }
  end

  def show_all_players
    logger.debug "Loading match data with round query filter #{params[:round_name]}"

    @data = Player.all.map {|player|
      player_scores = MatchScore
        .joins("LEFT JOIN matches ON match_scores.match_id = matches.id")
        .select("match_scores.*, matches.round_name")
        .where(:player => player)
        .where("matches.round_name like ?", "%#{params[:round_name]}%")

      player_accuracies = player_scores.map(&method(:score_accuracy))

      {
        :name => player.name,
        :online_id => player.id,
        :matches_played => Match
          .where("round_name like ?", "%#{params[:round_name]}%")
          .where(:player_red => player).or(Match.where(:player_blue => player)).count,
        :matches_won => Match
          .where("round_name like ?", "%#{params[:round_name]}%")
          .where(:winner => player.id).count,
        :maps_played => player_scores.count(:all),
        # TODO: figure out how to do a count where for maps won in the DB itself o.o
        :maps_won => MatchScore
          .joins("LEFT JOIN matches ON match_scores.match_id = matches.id")
          .select("match_scores.beatmap_id, MAX(match_scores.score), match_scores.player_id, matches.round_name")
          .group(:beatmap_id, :match_id)
          .where(:pass => true)
          .where("matches.round_name like ?", "%#{params[:round_name]}%")
          .all
          .to_a
          .select {|s| s.player_id == player.id}
          .length,
        :best_accuracy => (player_accuracies.max * 100.0).round(2),
        :average_accuracy => (player_accuracies.reduce(0, :+) / player_accuracies.count.to_f * 100.0).round(2),
        :perfect_count => player_scores.where(:perfect => true).count(:all),
        :average_misses => player_scores.average(:count_miss).round(2),
        :total_misses => player_scores.sum(:count_miss),
        :average_score => player_scores.average(:score).round(2),
        :total_score => player_scores.sum(:score),
        :maps_failed => player_scores.where(:player_id => player.id, :pass => false).count(:all),
        :full_combos => player_scores
          .joins("LEFT JOIN beatmaps ON match_scores.beatmap_id = beatmaps.online_id")
          .select("match_scores.beatmap_id, match_scores.player_id, match_scores.count_miss, match_scores.max_combo, beatmaps.max_combo")
          .where("count_miss = 0 and (beatmaps.max_combo - match_scores.max_combo) <= (0.01 * beatmaps.max_combo)")
          .count(:all),
      } if player_scores.count(:all) != 0
      }.compact
  end

  private
  def score_accuracy(score)
    # https://osu.ppy.sh/help/wiki/Accuracy
    ((50 * score.count_50) + (100 * score.count_100) + (300 * score.count_300)) / (300 * (score.count_miss + score.count_50 + score.count_100 + score.count_300))
      .to_f
  end
end
