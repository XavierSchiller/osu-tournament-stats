##
# Handles all match related operations in the application.
class MatchesController < ApplicationController
  before_action :authenticate_player!, except: %i[show show_match]

  def show
    @data = Match.all.where(tournament_id: params[:tournament_id])

    respond_to do |format|
      format.html
      format.json { render json: @data, status: :ok }
    end
  end

  def show_match
    @data = StatisticsServices::PlayerStatistics_Legacy.new.get_all_player_stats_for_match(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @data, status: :ok }
    end
  end

  def add
    begin
      match = osu_api_service.load_match(
        osu_match_id: add_match_params[:osu_match_id],
        red_captain: add_match_params[:red_captain],
        blue_captain: add_match_params[:blue_captain],
        referees: add_match_params[:referees],
        discard_list: add_match_params[:discard_list]&.map(&:to_i),
        round_name: add_match_params[:round_name],
        tournament_id: add_match_params[:tournament_id],
      )

      if match.nil?
        return render json: { message: 'An error occurred', code: 'E_UNKNOWN_ERROR' }, status: :internal_server_error
      end

      render json: match, status: :ok
    rescue OsuApiParserExceptions::MatchExistsError
      render json: { error: "Match with osu! multiplayer ID #{add_match_params[:online_id]} already exists" }, status: :conflict
    rescue OsuApiParserExceptions::MatchLoadFailedError
      render json: { error: 'Failed to retrieve match from osu! API' }, status: :not_found
    rescue OsuApiParserExceptions::MatchParseFailedError
      render json: { error: 'An error occurred while parsing the match' }, status: :internal_server_error
    end
  end

  def delete
    Match.find(params[:id]).destroy
  end

  private

  def add_match_params
    params.permit(
      :osu_match_id,
      :round_name,
      :tournament_id,
      :red_captain,
      :blue_captain,
      :tournament_id,
      referees: [],
      discard_list: [],
    )
  end

  def osu_api_service
    ApiServices::OsuApi.new
  end
end
