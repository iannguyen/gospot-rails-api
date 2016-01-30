class Match < ActiveRecord::Base
  include MatchesHelper

  validates :team_1_id, :team_2_id, :team_1_score, :team_2_score, :team_1_odds,
            :team_2_odds, :location, :start_hour, presence: true
  validates :open, inclusion: { in: [true, false] }
  validates :team_1_score, :team_2_score, inclusion: { in: (0..16).to_a }

  belongs_to :team_1, class_name: 'Team', foreign_key: 'team_1_id'
  belongs_to :team_2, class_name: 'Team', foreign_key: 'team_2_id'

  has_many :bets
  has_many :skins, through: :bets
  has_many :users, through: :bets
  has_many :teams, through: :bets

  attr_accessor :total, :teams

  def over?
    team_1_score == 16 || team_2_score == 16
  end

  def winner
    team_1_score == 16 ? team_1 : team_2 if over?
  end

  def winner_mulplier
    (total / winner.total) - 1
  end

  def loser
    team_1_score == 16 ? team_2 : team_1 if over?
  end

  def teams
    [team_1, team_2]
  end

  def total
    skins.sum(:price)
  end

  def team_1_odds
    return 0 if total.zero?
    (team_1.total / total).to_f.round(2)
  end

  def team_2_odds
    return 0 if total.zero?
    (team_2.total / total).to_f.round(2)
  end

  def distribute
    winners = winner_returns
    loser_skins = loser.skins.order(:price).reverse_order
    payout_table = PayoutTable.new(loser_skins, winners)
    payout_table.payout!
    destroy_bets!
  end

  private

  def winner_returns
    winners = {}
    multiplier = winner_mulplier
    winning_team_bets = Bet.includes(:skins)
                        .includes(:team)
                        .includes(:user)
                        .where(team_id: winner.id)
                        .sort_by(&:total).reverse!

    winning_team_bets.each do |bet|
      returned_payout = bet.user.payouts.new(skins: bet.skins)
      winners[bet.user_id] = {
        payout: returned_payout,
        profit: (bet.total * multiplier)
      }
      bet.skins.each { |skin| skin.bet_id = nil }
    end
    winners
  end

  def destroy_bets!
    Bet.where(match_id: id).destroy_all
  end
end