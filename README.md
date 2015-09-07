# Deprecated

I regret to inform you that this API is now deprecated. With the significant changes that have occurred on ESPN.com i decided to re-write the gem in a more object-oriented approach along with a full TDD suite. Please see https://github.com/mikesilvis/sports_api for continued API usage. 

# ESPN Scraper

ESPN Scraper is a simple gem for scraping teams and scores from `ESPN`'s website. Please note that `ESPN` is not involved with this gem or me in any way. I chose `ESPN` because it is a leader in sports statistics and has a robust website. 


```ruby
ESPN.responding?
# => true
```

Lets begin...

#### Open console with the gem required

``` bash
$  rake espn_scraper:console
```

#### Supported leagues

The gem only supports the following leagues:

```ruby
ESPN.leagues
# => [ "nfl", "mlb", "nba", "nhl", "ncf", "ncb" ]
```

Which are the NFL, MLB, NBA, NHL, NCAA D1 Football, NCAA D1 Men's Basketball respectively.

#### Scrape Divisions

You can get all the divisions in each league.

```ruby
ESPN::Division.find(ESPN::NHL)
# => [
# 		 "Central Division",
# 		 "Pacific Division",
# 		 "Atlantic Division", 
# 		 "Metropolitan Division"
# 	 ]
```

#### Scrape teams

You can get the teams in each league by acronym. It returns a hash of each division with an array of hashes for each team in the division.

```ruby
ESPN::Team.find(ESPN::NBA)
# => {
#   "atlantic"=> [ 
#     { :name => "Boston Celtics", :data_name => "bos" },  
#     { :name => "Brooklyn Nets", :data_name => "bkn" }, 
#     { :name => "New York Knicks", :data_name => "ny" }, 
#     { :name => "Philadelphia 76ers", :data_name => "phi" }, 
#     { :name => "Toronto Raptors", :data_name => "tor" }
#   ]
#   "pacific" => ...
# }
```

#### Scraping scores



You'll notice the teams are identified with the same `:data_name` and is ESPN's unique identifier

``` ruby 
ESPN::Score.find(ESPN::NBA, Date.today)
# => [
#  {
#    :game_date=>Wed, 18 Mar 2015,
#    :home_team=>"cle",
#    :home_team_name=>"Cavaliers",
#    :away_team=>"bkn",
#    :away_team_name=>"Nets",
#    :home_score=>0,
#    :away_score=>0,
#    :home_team_rank=>"",
#    :away_team_rank=>"",
#    :home_team_record=>"43-26",
#    :away_team_record=>"27-38",
#    :state=>"pregame",
#    :start_time=>"7:00 PM ET",
#    :preview=>"400579297",
#    :line=>"",
#    :league=>"nba"
#  },
#  {
#    :game_date=>Wed, 18 Mar 2015,
#    :home_team=>"phi",
#    :home_team_name=>"76ers",
#    :away_team=>"det",
#    :away_team_name=>"Pistons",
#    :home_score=>0,
#    :away_score=>0,
#    :home_team_rank=>"",
#    :away_team_rank=>"",
#    :home_team_record=>"15-52",
#    :away_team_record=>"24-43",
#    :state=>"pregame",
#    :start_time=>"7:00 PM ET",
#    :preview=>"400579298",
#    :line=>"",
#    :league=>"nba"
#  }
#]

 ```
 
#### Scraping Boxscores

For more detailed information about a particular game you may want to see who scored, penalties, game location, etc.

``` ruby
ESPN::Boxscore.find(ESPN::NHL, 400564477)
# => {
#  :game_date=>2015-01-27 19:00:00 -0800,
#  :arena=>"CONSOL Energy Center, Pittsburgh, Pennsylvania",
#  :league=>"nhl",
#  :game_id=>400564477,
#  :state=>"postgame",
#  :time_remaining_summary=>"Final",
#  :home_team=>"pit",
#  :home_team_name=>"Penguins",
#  :home_team_abbr=>"PIT",
#  :home_team_score=>"5",
#  :home_team_record=>"27-12-8",
#  :away_team=>"wpg",
#  :away_team_name=>"Jets",
#  :away_team_abbr=>"WPG",
#  :away_team_score=>"3",
#  :away_team_record=>"26-15-8",
#  :score_summary=>
#  [
#    ["", "1", "2", "3", "T"],
#    ["wpg", "0", "2", "1", "3"],
#    ["pit", "1", "1", "3", "5"]
#  ],
#  :start_time=>"7:00 PM ET, January 27, 2015",
#  :location=>"CONSOL Energy Center, Pittsburgh, Pennsylvania",
#  :score_detail=>
#  [
#    {
#      :header_info=>"1st Period Summary",
#      :header_row=>["Time", "Team", "Scoring Detail", "WPG", "PIT"],
#      :content_info=>
#      [
#        ["pit",
#         "7:09",
#         "Nick Spaling (7) Assists: David Perron, Kris Letang"
#      ]
#      ],
#      :penalty_info=>false
#    },
#    {
#      :header_info=>"2nd Period Summary",
#      :header_row=>[
#        "Time",
#        "Team",
#        "Scoring Detail",
#        "WPG",
#        "PIT"
#      ],
#      :content_info=>
#      [
#        ["wpg",
#         "2:13",
#         "Chris Thorburn (5) Assists: Adam Lowry,
#        Evander Kane"
#      ],
#      [
#        "wpg",
#        "12:47",
#        "Jacob Trouba (5) Assists: Evander Kane, Dustin Byfuglien"
#      ],
#      [
#        "pit",
#        "19:55",
#        "Steve Downie (9) Assists: Kris Letang, Marcel Goc"
#      ]
#      ],
#      :penalty_info=>false},
#      {
#        :header_info=>"3rd Period Summary",
#        :header_row=>[
#          "Time",
#          "Team",
#          "Scoring Detail",
#          "WPG",
#          "PIT"
#        ],
#        :content_info=>
#        [
#          [
#            "wpg",
#            "0:59",
#            "Adam Lowry (6) Assists: Chris Thorburn, Evander Kane"
#          ],
#          [
#            "pit",
#            "4:23",
#            "David Perron (11) (Power Play) Assists: Kris Letang, Chris Kunitz"
#          ],
#          [
#            "pit",
#            "7:52",
#            "Brandon Sutter (10) (Power Play) Assists: Paul Martin, Kris Letang"
#          ],
#          ["pit",
#           "19:32",
#           "Patric Hornqvist (14) Assists: Paul Martin, Kris Letang"
#          ]
#        ],
#        :penalty_info=>false
#      }
#  ]
#}

```

### Scraping Game Summaries
``` ruby
ESPN::Recap.find(ESPN::NHL, 400564477)
# => {
#   :content=> "PITTSBURGH --  For a team seemingly so reliant on megastars Sidney Crosby and Evgeni Malkin...",
#   :headline=>"Sidney Crosby-less Penguins rally for win over Jets",
#   :url=>"http://m.espn.go.com/nhl/gamecast?gameId=400564477&appsrc=sc",
#   :game_id=>400564477,
#   :league=>"nhl"
# }
```

#### Scraping Game Previews
For detailed information about a game including the write up
``` ruby
ESPN::Preview.find(ESPN::NHL, 400564406)
# => {
#   :content=> "(AP) --  If someone said the New York Rangers would be without star goalie Henrik Lundqvist for more than a month during # a crucial stretch...",
#   :headline=>"Blackhawks-Rangers\u00A0Preview",
#   :url=>"http://espn.go.com/nhl/preview?gameId=400564406",
#   :game_id=>400564406,
#   :league=>"nhl",
#   :start_time=>"8:00 PM ET, March 18, 2015",
#   :location=>"Madison Square Garden, New York, New York",
#   :home_team_name=>"Rangers",
#   :home_team=>"nyr",
#   :home_team_record=>"44-1",
#   :away_team_name=>"Blackhawks",
#   :away_team=>"chi",
#   :away_team_record=>"42-2",
#   :series=> [
#     {
#       :date=>Sun, 08 Mar 2015,
#       :away_team=>"nyr",
#       :away_team_score=>"1",
#       :home_team=>"chi",
#       :home_team_score=>"0",
#       :boxscore=>"400564404"
#     }
#   ],
#   :channel=>"NBCSN"
# }

```

#### Photos
You can also scrape photos from a particular game using the same boxscore game id

``` ruby
ESPN::Photo.find(ESPN::NHL, 400564477)
# => {
#   :photos=>
#  [
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462382812.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383030.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383040.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383046.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383058.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383130.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383132.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383286.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462382812.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383030.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383040.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383046.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383058.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383130.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383132.jpg",
#    "http://a.espncdn.com/combiner/i?img=media%2Fgettyphoto%2F2015%5C01%5C27%5C462383286.jpg"
#  ],
#  :url=>"http://espn.go.com/nhl/photos?gameId=400564477",
#  :game_id=>400564477,
#  :league=>"nhl"
#}


```

#### Standings

For standings you can pass: `ESPN::Standing::LEAGUE`, `ESPN::Standing::CONFERENCe`,  `ESPN::Standing::DIVISION`, 

``` ruby
ESPN::Standing.find(ESPN::NHL, ESPN::Standing::LEAGUE)
# => {
#   :league=>"nhl",
#   :headers=>["GP", "W", "L", "OTL", "PTS"],
#  :teams=>
#  {
#    "Nhl"=>
#    [
#      {
#        :team=>"nyr",
#        :team_name=>"NY Rangers",
#        :league=>"nhl",
#        :stats=>["68", "44", "17", "7", "95"]
#      },
#      {
#        :team=>"stl",
#        :team_name=>"St. Louis",
#        :league=>"nhl",
#        :stats=>["70", "45", "20", "5", "95"]
#      },
#      {
#        :team=>"mtl",
#        :team_name=>"Montreal",
#        :league=>"nhl",
#        :stats=>["71", "44", "20", "7", "95"]
#      },
#      {
#        :team=>"ana",
#        :team_name=>"Anaheim",
#        :league=>"nhl",
#        :stats=>["71", "44", "20", "7", "95"]
#      },
#  	  ....
#    ]
#  }
#}

```

#### League Schedule

``` ruby
ESPN::Schedule::League.find(ESPN::NFL)
# => [Sun, 09 Aug 2015, Sun, 04 Oct 2015, Sun, 25 Oct 2015, Sun, 01 Nov 2015]
```

#### Team Schedule
Pass a league, and team data name
``` ruby
ESPN::Schedule::Team.find(ESPN::NHL, 'pit')
# => {
#   :league=>"nhl",
#   :team_name=>"pit",
#   :games=>
#   [
#     {
#       :over=>true,
#       :date=>Mon, 22 Sep 2014,
#       :opponent=>"det",
#       :opponent_name=>"Detroit",
#       :is_away=>false,
#       :result=>"2-1",
#       :win=>false
#     },
#     {
#       :over=>true,
#       :date=>Tue, 23 Sep 2014,
#       :opponent=>"cbj",
#       :opponent_name=>"Columbus",
#       :is_away=>true,
#       :result=>"2-0",
#       :win=>false
#     },
#     {
#       :over=>false,
#       :date=>Sat, 21 Mar 2015,
#       :opponent=>"ari",
#       :opponent_name=>"Arizona",
#       :is_away=>true,
#       :time=>Sun, 22 Mar 2015 02:00:00 +0000},
#       {
#         :over=>false,
#         :date=>Tue, 24 Mar 2015,
#         :opponent=>"stl",
#         :opponent_name=>"St. Louis",
#         :is_away=>false,
#         :time=>Wed, 25 Mar 2015 00:00:00 +0000
#       },
#       {
#         :over=>false,
#         :date=>Sat, 11 Apr 2015,
#         :opponent=>"buf",
#         :opponent_name=>"Buffalo",
#         :is_away=>true,
#         :time=>Sun, 12 Apr 2015 00:00:00 +0000
#       }
#   ]
# }
```

#### Caching

You may have noticed that some requests can be extremely slow because they are making multiple get requests to ESPN.com for the data needed. Because of this there is a built in cache mechanism that uses just in memory store. If you are using a rails app or have memcache available to you I highly recommend using that instead. 

##### Rails
In an initializer

``` ruby
ESPN::Cache.client = Rails.cache

```

##### Ruby

If you aren't using rails, you can still write your own memory store using memcache. All you need to do is create a class that abides by `fetch(cache_key, attrs, &block)`, `read(cache_key)`, `write(cache_key, data, attrs = {})`, `clear(key)`

## Installing

Add the gem to your `Gemfile`

```ruby
gem 'espn_scraper', git: 'git://github.com/aj0strow/espn-scraper.git'
# or
gem 'espn_scraper', github: 'aj0strow/espn-scraper'
```

..and then require it. I personally use it in rake tasks of a Rails app.

```ruby
require 'espn_scraper'
```

## Contributing

Please report back if something breaks on you!

Also please let me know if any of the data names get outdated. For instance a bunch of NFL data names were recently changed. You can make fixes temporarily with the following:

```ruby
ESPN::DATA_NAME_FIXES['nfl']['gnb'] = 'gb'
```

Future plans:
- Get start and end dates of a season




