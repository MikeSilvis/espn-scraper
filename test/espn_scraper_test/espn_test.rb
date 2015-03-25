require 'test_helper'

class BoilerplateTest < EspnTest

  test 'espn is up' do
    VCR.use_cassette(__method__) do
      assert ESPN.responding?
      assert !ESPN.down?
    end
  end

  test 'paths are working' do
    assert_equal 'http://scores.espn.go.com', ESPN.url('scores')
    assert_equal 'http://espn.go.com/nba/teams', ESPN.url('nba', 'teams')
  end

  test 'error message works' do
    VCR.use_cassette(__method__) do
      assert_raises(ArgumentError) do
        ESPN.get('bad-api-keyword')
      end
    end
  end

  test 'get pages is working' do
    VCR.use_cassette(__method__) do
      assert ESPN.get('scores')
    end
  end

  test 'dasherize strings' do
    assert_equal 'string-is-dashed', ESPN.send(:dasherize, 'String is dashed')
  end

  test 'leagues' do
    leagues = 'nfl mlb nba nhl ncf ncb'.split
    assert_equal leagues, ESPN.leagues
  end

end
