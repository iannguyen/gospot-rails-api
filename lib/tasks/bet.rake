desc 'Create new bets'

task generate_bets_and_skins: :environment do
  puts "GENERATING RANDOM BETS AND SKINS!"
  Bet.send(:generate_bets!)
end
