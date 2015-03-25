ERROR_CHECKS = 1

require 'minitest/autorun'
require 'vcr'
require 'espn_scraper'
require 'timecop'
require 'rr'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

class EspnTest < Minitest::Test
  class << self

    def test(test_name, &block)
      define_method("test_#{ test_name.gsub(/\s+/, '_') }", &block)
    end

  end

  def all_names_present?(ary)
    ary.map do |obj|
      h, a = obj[:home_team], obj[:away_team]
      test = h.nil? || (h && h.empty?) || a.nil? || (a && a.empty?)
      puts h, a if test
      test
    end.count(true) == 0
  end

  def whole_year
    Date.today..Date.today.prev_year
  end

  def random_days(amount = ERROR_CHECKS)
    whole_year.to_a.sample(amount)
  end

  def random_weeks(amount = ERROR_CHECKS)
    (1..17).to_a.sample(amount)
  end
end
