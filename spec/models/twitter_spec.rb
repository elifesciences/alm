require 'spec_helper'

describe Twitter do
  let(:twitter) { FactoryGirl.create(:twitter) }
  
  it "should report that there are no events if the doi is missing" do
    article_without_doi = FactoryGirl.build(:article, :doi => "")
    twitter.get_data(article_without_doi).should eq({ :events => [], :event_count => nil })
  end
  
  context "use the Twitter API" do    
    it "should catch errors with the Twitter API" do
      article = FactoryGirl.build(:article, :url => "http://www.plosone.org/article/info%3Adoi%2F10.1371%2Fjournal.pone.0000001")
      error = { "error"=>"not_found", "reason"=>"missing" }
      stub = stub_request(:get, twitter.get_query_url(article)).to_return(:body => error, :status => [408, "Request Timeout"])
      twitter.get_data(article).should eq({ :events => [], :event_count => nil })
      stub.should have_been_requested
      ErrorMessage.count.should == 1
      error_message = ErrorMessage.first
      error_message.class_name.should eq("Net::HTTPRequestTimeOut")
      error_message.message.should include("Request Timeout")
      error_message.status.should == 408
      error_message.source_id.should == twitter.id
    end

  end
end