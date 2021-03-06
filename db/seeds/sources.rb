# encoding: UTF-8
# Load sources
viewed = Group.find_or_create_by_name(name: 'viewed', display_name: 'Viewed')
saved = Group.find_or_create_by_name(name: 'saved', display_name: 'Saved')
discussed = Group.find_or_create_by_name(name: 'discussed', display_name: 'Discussed')
cited = Group.find_or_create_by_name(name: 'cited', display_name: 'Cited')
recommended = Group.find_or_create_by_name(name: 'recommended', display_name: 'Recommended')
other = Group.find_or_create_by_name(name: 'other', display_name: 'Other')

# These sources are installed and activated by default
citeulike = Citeulike.find_or_create_by_name(
  :name => 'citeulike',
  :display_name => 'CiteULike',
  :description => 'CiteULike is a free social bookmarking service for scholarly content.',
  :state_event => 'activate',
  :group_id => saved.id)
pubmed = PubMed.find_or_create_by_name(
  :name => 'pubmed',
  :display_name => 'PubMed Central',
  :description => 'PubMed Central is a free full-text archive of biomedical ' \
                  'literature at the National Library of Medicine.',
  :state_event => 'activate',
  :group_id => cited.id)
wordpress = Wordpress.find_or_create_by_name(
  :name => 'wordpress',
  :display_name => 'Wordpress.com',
  :description => 'Wordpress.com is one of the largest blog hosting platforms.',
  :state_event => 'activate',
  :group_id => discussed.id)
reddit = Reddit.find_or_create_by_name(
  :name => 'reddit',
  :display_name => 'Reddit',
  :description => 'User-generated news links.',
  :state_event => 'activate',
  :group_id => discussed.id)
wikipedia = Wikipedia.find_or_create_by_name(
  :name => 'wikipedia',
  :display_name => 'Wikipedia',
  :description => 'Wikipedia is a free encyclopedia that everyone can edit.',
  :state_event => 'activate',
  :group_id => discussed.id)
datacite = Datacite.find_or_create_by_name(
  :name => 'datacite',
  :display_name => 'DataCite',
  :description => 'Helping you to find, access, and reuse research data.',
  :group_id => cited.id)

# These sources are not installed by default
pmc_europe = PmcEurope.find_or_create_by_name(
  :name => 'pmceurope',
  :display_name => 'Europe PubMed Central',
  :description => 'Europe PubMed Central (Europe PMC) is an archive of life ' \
                  'sciences journal literature.',
  :group_id => cited.id)
pmc_europe_data = PmcEuropeData.find_or_create_by_name(
  :name => 'pmceuropedata',
  :display_name => 'Europe PubMed Central Database Citations',
  :description => 'Europe PubMed Central (Europe PMC) Database is an archive of ' \
                  'life sciences journal data.',
  :group_id => cited.id)
scienceseeker = ScienceSeeker.find_or_create_by_name(
  :name => 'scienceseeker',
  :display_name => 'ScienceSeeker',
  :description => 'Research Blogging is a science blog aggregator.',
  :group_id => discussed.id)
nature = Nature.find_or_create_by_name(
  :name => 'nature',
  :display_name => 'Nature Blogs',
  :description => 'Nature Blogs is a science blog aggregator.',
  :group_id => discussed.id)
openedition = Openedition.find_or_create_by_name(
  :name => 'openedition',
  :display_name => 'OpenEdition',
  :description => 'OpenEdition is the umbrella portal for OpenEdition Books, ' \
                  'Revues.org, Hypotheses and Calenda in the humanities and ' \
                  'social sciences.',
  :group_id => discussed.id)
