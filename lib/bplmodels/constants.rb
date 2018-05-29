module Bplmodels
  class Constants

    GENRE_LOOKUP = {
      'Cards' => {id: 'tgm001686', authority: 'gmgpc'},
      'Correspondence' => {id: 'tgm002590', authority: 'lctgm'},
      'Documents' => {id: 'tgm003185', authority: 'gmgpc'},
      'Drawings' => {id: 'tgm003279', authority: 'gmgpc'},
      'Ephemera' => {id: 'tgm003634', authority: 'gmgpc'},
      'Manuscripts' => {id: 'tgm012286', authority: 'gmgpc'},
      'Maps' => {id: 'tgm006261', authority: 'gmgpc'},
      'Objects' => {id: 'tgm007159', authority: 'lctgm'},
      'Paintings' => {id: 'tgm007393', authority: 'gmgpc'},
      'Photographs' => {id: 'tgm007721', authority: 'gmgpc'},
      'Posters' => {id: 'tgm008104', authority: 'gmgpc'},
      'Prints' => {id: 'tgm008237', authority: 'gmgpc'},
      'Newspapers' => {id: 'tgm007068', authority: 'lctgm'},
      'Sound recordings' => {id: 'tgm009874', authority: 'lctgm'},
      'Motion pictures' => {id: 'tgm006804', authority: 'lctgm'},
      'Periodicals' => {id: 'tgm007641', authority: 'gmgpc'},
      'Books' => {id: 'tgm001221', authority: 'gmgpc'},
      'Albums' => {id: 'tgm000229', authority: 'gmgpc'},
      'Musical notation' => {id: 'tgm006926', authority: 'lctgm'},
      'Music' => {id: 'tgm006906', authority: 'lctgm'},
    }

    RESOURCE_TYPES = [
      'still image', 'text', 'cartographic', 'notated music', 'sound recording',
      'sound recording-musical', 'sound recording-nonmusical', 'moving image',
      'three dimensional object', 'software, multimedia', 'mixed material'
    ].freeze

    MIME_TYPES = {
        'pdf' => 'application/pdf', 'jpeg' => 'image/jpeg',
        'jpg' => 'image/jpeg', 'png' => 'image/png',
        'tif' => 'image/tiff', 'wav' => 'audio/vnd.wave',
        'mp4' => 'video/mp4', 'mov' => 'video/quicktime',
        'avi' => 'video/avi', 'mpg' => 'video/mpeg',
        'video/mpeg' => 'video/mpeg', 'msword' => 'application/msword',
        'html' => 'text/html', 'mp3' => 'audio/mpeg',
        'audio/mpeg' => 'audio/mpeg'
    }

    COUNTRY_TGN_LOOKUP = {
      'United States' => {tgn_id: 7012149, tgn_country_name: 'United States'},
      'Canada' => {tgn_id: 7005685, tgn_country_name: 'Canada'},
      'France' => {tgn_id: 1000070, tgn_country_name: 'France'},
      'Vietnam' => {tgn_id: 1000145, tgn_country_name: 'Viet Nam'},
      'South Africa' => {tgn_id: 1000193, tgn_country_name: 'South Africa'},
      'Philippines' => {tgn_id: 1000135, tgn_country_name: 'Pilipinas'},
      'China' => {tgn_id: 1000111, tgn_country_name: 'Zhongguo'},
      'Japan' => {tgn_id: 1000120, tgn_country_name: 'Nihon'}
    }

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
    ].freeze

    OCR_STOPWORDS = %w[
      the The THE in In IN to To TO a A and And AND for For FOR at At AT of Of OF
      an An AN or Or OR by By BY as As AS on On ON
    ].freeze

    # from MARC Appendix F - Initial Definite and Indefinite Articles
    # see http://www.loc.gov/marc/bibliographic/bdapndxf.html
    # BUT we are excluding:
    # ['am', 'as', 'an t-', 'ang mga', 'bat', 'hen', 'in', 'it', 'na h-',
    #  'o', 'to', 'ton', 'us']
    # since these are tougher to deal with (or non-English specific),
    # and unlikely to be used
    NONSORT_ARTICLES = %w[
      a a' al al- an ane ang az bir d' da das de dei dem den der des det di
      die dos e 'e een eene egy ei ein eine einem einen einer eines eit el el-
      els en enne et ett eyn eyne gl' gli ha- hai he hē he- heis hena henas het
      hin hina hinar hinir hinn hinna hinnar hinni hins hinu hinum hið ho hoi i
      ih' il il- ka ke l' l- la las le les lh lhi li lis lo los lou lu mga mia
      'n na njē ny 'o os 'r 's 't ta tais tas tē tēn tēs the tō tois tōn tou um
      uma un un' una une unei unha uno uns unui y ye yr
    ].freeze

  end
end
