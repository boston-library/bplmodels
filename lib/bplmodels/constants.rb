module Bplmodels
  class Constants
    GENRE_LOOKUP = {}
    GENRE_LOOKUP['Cards'] = {:id=>'tgm001686', :authority=>'gmgpc'}
    GENRE_LOOKUP['Correspondence'] = {:id=>'tgm002590', :authority=>'lctgm'}
    GENRE_LOOKUP['Documents'] = {:id=>'tgm003185', :authority=>'gmgpc'}
    GENRE_LOOKUP['Drawings'] = {:id=>'tgm003279', :authority=>'gmgpc'}
    GENRE_LOOKUP['Ephemera'] = {:id=>'tgm003634', :authority=>'gmgpc'}
    GENRE_LOOKUP['Manuscripts'] = {:id=>'tgm012286', :authority=>'gmgpc'}
    GENRE_LOOKUP['Maps'] = {:id=>'tgm006261', :authority=>'gmgpc'}
    GENRE_LOOKUP['Objects'] = {:id=>'tgm007159', :authority=>'lctgm'}
    GENRE_LOOKUP['Paintings'] = {:id=>'tgm007393', :authority=>'gmgpc'}
    GENRE_LOOKUP['Photographs'] = {:id=>'tgm007721', :authority=>'gmgpc'}
    GENRE_LOOKUP['Posters'] = {:id=>'tgm008104', :authority=>'gmgpc'}
    GENRE_LOOKUP['Prints'] = {:id=>'tgm008237', :authority=>'gmgpc'}
    GENRE_LOOKUP['Newspapers'] = {:id=>'tgm007068', :authority=>'lctgm'}
    GENRE_LOOKUP['Sound recordings'] = {:id=>'tgm009874', :authority=>'lctgm'}
    GENRE_LOOKUP['Motion pictures'] = {:id=>'tgm006804', :authority=>'lctgm'}
    GENRE_LOOKUP['Periodicals'] = {:id=>'tgm007641', :authority=>'gmgpc'}
    GENRE_LOOKUP['Books'] = {:id=>'tgm001221', :authority=>'gmgpc'}
    GENRE_LOOKUP['Albums'] = {:id=>'tgm000229', :authority=>'gmgpc'}
    GENRE_LOOKUP['Musical notation'] = {:id=>'tgm006926', :authority=>'lctgm'}
    GENRE_LOOKUP['Music'] = {:id=>'tgm006906', :authority=>'lctgm'}

    COUNTRY_TGN_LOOKUP = {}
    COUNTRY_TGN_LOOKUP['United States'] = {:tgn_id=>7012149, :tgn_country_name=>'United States'}
    COUNTRY_TGN_LOOKUP['Canada'] = {:tgn_id=>7005685, :tgn_country_name=>'Canada'}
    COUNTRY_TGN_LOOKUP['France'] = {:tgn_id=>1000070, :tgn_country_name=>'France'}
    COUNTRY_TGN_LOOKUP['Vietnam'] = {:tgn_id=>1000145, :tgn_country_name=>'Viet Nam'}
    COUNTRY_TGN_LOOKUP['South Africa'] = {:tgn_id=>1000193, :tgn_country_name=>'South Africa'}
    COUNTRY_TGN_LOOKUP['Philippines'] = {:tgn_id=>1000135, :tgn_country_name=>'Pilipinas'}
    COUNTRY_TGN_LOOKUP['China'] = {:tgn_id=>1000111, :tgn_country_name=>'Zhongguo'}
    COUNTRY_TGN_LOOKUP['Japan'] = {:tgn_id=>1000120, :tgn_country_name=>'Nihon'}

    STATE_ABBR = {
        'AL' => 'Alabama',
        'AK' => 'Alaska',
        'AS' => 'America Samoa',
        'AZ' => 'Arizona',
        'AR' => 'Arkansas',
        'CA' => 'California',
        'CO' => 'Colorado',
        'CT' => 'Connecticut',
        'DE' => 'Delaware',
        'DC' => 'District of Columbia',
        'FM' => 'Micronesia1',
        'FL' => 'Florida',
        'GA' => 'Georgia',
        'GU' => 'Guam',
        'HI' => 'Hawaii',
        'ID' => 'Idaho',
        'IL' => 'Illinois',
        'IN' => 'Indiana',
        'IA' => 'Iowa',
        'KS' => 'Kansas',
        'KY' => 'Kentucky',
        'LA' => 'Louisiana',
        'ME' => 'Maine',
        'MH' => 'Islands1',
        'MD' => 'Maryland',
        'MA' => 'Massachusetts',
        'MI' => 'Michigan',
        'MN' => 'Minnesota',
        'MS' => 'Mississippi',
        'MO' => 'Missouri',
        'MT' => 'Montana',
        'NE' => 'Nebraska',
        'NV' => 'Nevada',
        'NH' => 'New Hampshire',
        'NJ' => 'New Jersey',
        'NM' => 'New Mexico',
        'NY' => 'New York',
        'NC' => 'North Carolina',
        'ND' => 'North Dakota',
        'OH' => 'Ohio',
        'OK' => 'Oklahoma',
        'OR' => 'Oregon',
        'PW' => 'Palau',
        'PA' => 'Pennsylvania',
        'PR' => 'Puerto Rico',
        'RI' => 'Rhode Island',
        'SC' => 'South Carolina',
        'SD' => 'South Dakota',
        'TN' => 'Tennessee',
        'TX' => 'Texas',
        'UT' => 'Utah',
        'VT' => 'Vermont',
        'VI' => 'Virgin Island',
        'VA' => 'Virginia',
        'WA' => 'Washington',
        'WV' => 'West Virginia',
        'WI' => 'Wisconsin',
        'WY' => 'Wyoming'
    }

    NOTE_TYPES = [
        'acquisition', 'arrangement', 'bibliography', 'biographical/historical', 'citation/reference',
        'creation/production credits', 'date', 'exhibitions', 'funding', 'language', 'ownership', 'performers',
        'preferred citation', 'publications', 'statement of responsibility', 'venue'
    ]

  end
end
