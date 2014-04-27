require 'spec_helper'

describe Twitter do
  subject { FactoryGirl.create(:twitter) }

  it "should report that there are no events if the doi is missing" do
    article_without_doi = FactoryGirl.build(:article, :doi => "")
    subject.parse_data(article_without_doi).should eq(events: [], event_count: nil)
  end

  context "use the Twitter API" do
    it "should report if there are no events and event_count returned by the Twitter API" do
      article = FactoryGirl.build(:article, :doi => "10.1371/journal.pone.0044294")
      stub = stub_request(:get, subject.get_query_url(article)).to_return(:headers => { "Content-Type" => "application/json" }, :body => File.read(fixture_path + 'twitter_nil.json', encoding: 'UTF-8'), :status => 200)
      subject.parse_data(article).should eq(:events=>[], :event_count=>0, :event_metrics=>{:pdf=>nil, :html=>nil, :shares=>nil, :groups=>nil, :comments=>0, :likes=>nil, :citations=>nil, :total=>0})
      stub.should have_been_requested
    end

    it "should report if there are events and event_count returned by the Twitter API" do
      article = FactoryGirl.build(:article, :canonical_url => "http://www.plosone.org/article/info%3Adoi%2F10.1371%2Fjournal.pmed.0020124")
      stub = stub_request(:get, subject.get_query_url(article)).to_return(:headers => {"Content-Type" => "application/json"}, :body => File.read(fixture_path + 'twitter.json'), :status => 200)
      response = subject.parse_data(article)
      response[:event_count].should == 2

      event = response[:events].first
      event[:event_url].should eq("http://twitter.com/regrum/status/204270013081849857")

      event_data = event[:event]

      event_data[:id].should eq("204270013081849857")
      event_data[:text].should eq("Don't be blinded by science http://t.co/YOWRhsXb")
      event_data[:created_at].should eq("2012-05-20T17:59:00Z")
      event_data[:user].should eq("regrum")
      event_data[:user_name].should eq("regrum")
      event_data[:user_profile_image].should eq("http://a0.twimg.com/profile_images/61215276/regmanic2_normal.JPG")
    end

    it "should catch errors with the Twitter API" do
      article = FactoryGirl.build(:article, :doi => "10.1371/journal.pone.0000001")
      stub = stub_request(:get, subject.get_query_url(article)).to_return(:status => [408])
      subject.parse_data(article, options = { :source_id => subject.id }).should be_nil
      stub.should have_been_requested
      Alert.count.should == 1
      alert = Alert.first
      alert.class_name.should eq("Net::HTTPRequestTimeOut")
      alert.status.should == 408
      alert.source_id.should == subject.id
    end
  end
end
