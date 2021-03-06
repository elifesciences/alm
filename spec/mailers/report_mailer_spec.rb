require "spec_helper"

describe ReportMailer do
  describe "error report" do
    let(:report) { FactoryGirl.create(:error_report_with_admin_user) }
    let(:mail) { ReportMailer.send_error_report(report) }

    it "sends email" do
      mail.subject.should eq("[ALM] Error Report")
      mail.to.should eq([report.users.map(&:email).join(",")])
      mail.from.should eq([CONFIG[:notification_email]])
    end

    it "renders the body" do
      mail.body.encoded.should include("This is the ALM error report")
    end

    it "includes no reviews" do
      mail.body.encoded.should include("No review found.")
    end

    it "provides a link to the admin dashboard" do
      body_html = mail.body.parts.find { |p| p.content_type.match /html/ }.body.raw_source
      body_html.should have_link('Go to admin dashboard', href: alerts_url)
    end
  end

  describe "status report" do
    let(:report) { FactoryGirl.create(:status_report_with_admin_user) }
    let(:mail) { ReportMailer.send_status_report(report) }

    it "sends email" do
      mail.subject.should eq("[ALM] Status Report")
      mail.to.should eq([report.users.map(&:email).join(",")])
      mail.from.should eq([CONFIG[:notification_email]])
    end

    it "renders the body" do
      mail.body.encoded.should include("This is the ALM status report")
    end

    it "provides a link to the admin dashboard" do
      body_html = mail.body.parts.find { |p| p.content_type.match /html/ }.body.raw_source
      body_html.should have_link('Go to admin dashboard', href: status_url)
    end
  end

  describe "article statistics report" do
    let(:report) { FactoryGirl.create(:article_statistics_report_with_admin_user) }
    let(:mail) { ReportMailer.send_article_statistics_report(report) }

    it "sends email" do
      mail.subject.should eq("[ALM] Article Statistics Report")
      mail.bcc.should eq([report.users.map(&:email).join(",")])
      mail.to.should eq([CONFIG[:notification_email]])
      mail.from.should eq([CONFIG[:notification_email]])
    end

    it "renders the body" do
      mail.body.encoded.should include("This is the ALM article statistics report")
    end

    it "provides a link to the admin dashboard" do
      body_html = mail.body.parts.find { |p| p.content_type.match /html/ }.body.raw_source
      body_html.should have_link('Download report', href: "#{CONFIG[:public_server]}/files/alm_report.zip")
    end
  end

  describe "fatal error report" do
    let(:report) { FactoryGirl.create(:fatal_error_report_with_admin_user) }
    let(:source) { FactoryGirl.create(:source) }
    let(:message) { "#{source.display_name} has exceeded maximum failed queries. Disabling the source." }
    let(:mail) { ReportMailer.send_fatal_error_report(report, message) }

    it "sends email" do
      mail.subject.should eq("[ALM] Fatal Error Report")
      mail.to.should eq([report.users.map(&:email).join(",")])
      mail.from.should eq([CONFIG[:notification_email]])
    end

    it "renders the body" do
      mail.body.encoded.should include("Disabling the source")
    end

    it "provides a link to the admin dashboard" do
      body_html = mail.body.parts.find { |p| p.content_type.match /html/ }.body.raw_source
      body_html.should have_link('Go to admin dashboard', href: alerts_url(level: "fatal"))
    end
  end

  describe "stale source report" do
    let(:report) { FactoryGirl.create(:stale_source_report_with_admin_user) }
    let(:source) { FactoryGirl.create(:citeulike) }
    let(:source_ids) { [source.id] }
    let(:mail) { ReportMailer.send_stale_source_report(report, source_ids) }

    it "sends email" do
      mail.subject.should eq("[ALM] Stale Source Report")
      mail.to.should eq([report.users.map(&:email).join(",")])
      mail.from.should eq([CONFIG[:notification_email]])
    end

    it "renders the body" do
      mail.body.encoded.should include("The following sources have not been updated for 24 hours")
    end

    it "provides a link to the admin dashboard" do
      body_html = mail.body.parts.find { |p| p.content_type.match /html/ }.body.raw_source
      body_html.should have_link('Go to admin dashboard', href: alerts_url(:class => "SourceNotUpdatedError"))
    end
  end

  describe "missing workers report" do
    let(:report) { FactoryGirl.create(:missing_workers_report_with_admin_user) }
    let(:mail) { ReportMailer.send_missing_workers_report(report) }

    it "sends email" do
      mail.subject.should eq("[ALM] Missing Workers Report")
      mail.to.should eq([report.users.map(&:email).join(",")])
      mail.from.should eq([CONFIG[:notification_email]])
    end

    it "renders the body" do
      mail.body.encoded.should include("Some workers are missing")
    end

    it "provides a link to the admin dashboard" do
      body_html = mail.body.parts.find { |p| p.content_type.match /html/ }.body.raw_source
      body_html.should have_link('Go to admin dashboard', href: status_url)
    end
  end
end
