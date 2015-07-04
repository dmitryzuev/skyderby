# == Schema Information
#
# Table name: tournament_rounds
#
#  id            :integer          not null, primary key
#  order         :integer
#  tournament_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class TournamentRound < ActiveRecord::Base
  belongs_to :tournament
  has_many :tournament_matches
end