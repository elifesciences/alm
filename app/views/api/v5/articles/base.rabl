collection @articles

attributes :doi, :title, :canonical_url, :mendeley_uuid, :pmid, :pmcid, :issued, :viewed, :saved, :discussed, :cited, :update_date

unless params[:info] == "summary"
  child :retrieval_statuses => :sources do
    attributes :name, :display_name, :group_name, :events_url, :update_date, :new_metrics => :metrics

    attributes :events, :events_csl if ["detail","event"].include?(params[:info])
    attributes :by_day, :by_month, :by_year if ["detail","history"].include?(params[:info])
  end
end
