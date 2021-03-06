# encoding: UTF-8
# Load sources
viewed = Group.find_or_create_by_name(name: 'viewed', display_name: 'Viewed')
saved = Group.find_or_create_by_name(name: 'saved', display_name: 'Saved')
discussed = Group.find_or_create_by_name(name: 'discussed', display_name: 'Discussed')
cited = Group.find_or_create_by_name(name: 'cited', display_name: 'Cited')
recommended = Group.find_or_create_by_name(name: 'recommended', display_name: 'Recommended')
other = Group.find_or_create_by_name(name: 'other', display_name: 'Other')

# The following sources require passwords/API keys and are installed by default
crossref = CrossRef.find_or_create_by_name(
  :name => 'crossref',
  :display_name => 'CrossRef',
  :description => 'CrossRef is a non-profit organization that enables ' \
                  'cross-publisher citation linking.',
  :group_id => cited.id,
  :state_event => 'install',
  :username => nil,
  :password => nil)
scopus = Scopus.find_or_create_by_name(
  :name => 'scopus',
  :display_name => 'Scopus',
  :description => 'Scopus is an abstract and citation database of peer-' \
                  'reviewed literature.',
  :group_id => cited.id,
  :api_key => nil,
  :insttoken => nil)
mendeley = Mendeley.find_or_create_by_name(
  :name => 'mendeley',
  :display_name => 'Mendeley',
  :description => 'Mendeley is a reference manager and social bookmarking tool.',
  :group_id => saved.id,
  :state_event => 'install',
  :api_key => nil)
facebook = Facebook.find_or_create_by_name(
  :name => 'facebook',
  :display_name => 'Facebook',
  :description => 'Facebook is the largest social network.',
  :group_id => discussed.id,
  :state_event => 'install',
  :access_token => nil)
researchblogging = Researchblogging.find_or_create_by_name(
  :name => 'researchblogging',
  :display_name => 'Research Blogging',
  :description => 'Research Blogging is a science blog aggregator.',
  :group_id => discussed.id,
  :username => nil,
  :password => nil)

# The following sources require passwords/API keys and are not installed by default
pmc = Pmc.find_or_create_by_name(
  :name => 'pmc',
  :display_name => 'PubMed Central Usage Stats',
  :description => 'PubMed Central is a free full-text archive of biomedical ' \
                  'literature at the National Library of Medicine.',
  :queueable => false,
  :group_id => viewed.id,
  :url => nil,
  :journals => nil,
  :username => nil,
  :password => nil)
copernicus = Copernicus.find_or_create_by_name(
  :name => 'copernicus',
  :display_name => 'Copernicus',
  :description => 'Usage stats for Copernicus articles.',
  :group_id => viewed.id,
  :url => nil,
  :username => nil,
  :password => nil)
twitter_search = TwitterSearch.find_or_create_by_name(
  :name => 'twitter_search',
  :display_name => 'Twitter (Search API)',
  :description => 'Twitter is a social networking and microblogging service.',
  :group_id => discussed.id,
  :access_token => nil)
