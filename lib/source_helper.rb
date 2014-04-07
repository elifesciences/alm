# encoding: UTF-8

# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2014 by Public Library of Science, a non-profit corporation
# http://www.plos.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'faraday'
require 'faraday_middleware'
require 'faraday-cookie_jar'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'uri'

module SourceHelper
  DEFAULT_TIMEOUT = 60
  SourceHelperExceptions = [Faraday::Error::ClientError,
                            Delayed::WorkerTimeout,
                            Encoding::UndefinedConversionError,
                            ArgumentError].freeze
  # Errno::EPIPE, Errno::ECONNRESET

  def get_json(url, options = { timeout: DEFAULT_TIMEOUT })
    conn = conn_json
    conn.basic_auth(options[:username], options[:password]) if options[:username]
    conn.authorization :Bearer, options[:bearer] if options[:bearer]
    conn.options[:timeout] = options[:timeout]
    if options[:data]
      response = conn.post url, {}, options[:headers] do |request|
        request.body = options[:data]
      end
    else
      response = conn.get url, {}, options[:headers]
    end
    response.body
  rescue *SourceHelperExceptions => e
    rescue_faraday_error(url, e, options.merge(json: true))
  end

  def post_json(url, options = { data: nil, timeout: DEFAULT_TIMEOUT })
    get_json(url, options)
  end

  def get_xml(url, options = { timeout: DEFAULT_TIMEOUT })
    conn = conn_xml
    conn.basic_auth(options[:username], options[:password]) if options[:username]
    conn.authorization :Bearer, options[:bearer] if options[:bearer]
    conn.options[:timeout] = options[:timeout]
    if options[:data]
      response = conn.post url, {}, options[:headers] do |request|
        request.body = options[:data]
      end
    else
      response = conn.get url, {}, options[:headers]
    end
    # We have issues with the Faraday XML parsing
    Nokogiri::XML(response.body)
  rescue *SourceHelperExceptions => e
    rescue_faraday_error(url, e, options.merge(xml: true))
  end

  def post_xml(url, options = { data: nil, timeout: DEFAULT_TIMEOUT })
    get_xml(url, options)
  end

  def get_html(url, options = { timeout: DEFAULT_TIMEOUT })
    conn = conn_html
    conn.basic_auth(options[:username], options[:password]) if options[:username]
    conn.options[:timeout] = options[:timeout]
    response = conn.get url, {}, options[:headers]
    response.body
  rescue *SourceHelperExceptions => e
    rescue_faraday_error(url, e, options.merge(html: true))
  end

  def get_alm_data(id = "")
    get_json("#{couchdb_url}#{id}")
  end

  def get_alm_rev(id, options={})
    head_alm_data("#{couchdb_url}#{id}", options)
  end

  def head_alm_data(url, options = { timeout: DEFAULT_TIMEOUT })
    conn = conn_json
    conn.basic_auth(options[:username], options[:password]) if options[:username]
    conn.options[:timeout] = options[:timeout]
    response = conn.head url
    # CouchDB revision is in etag header. We need to remove extra double quotes
    rev = response.env[:response_headers][:etag][1..-2]
  rescue *SourceHelperExceptions => e
    rescue_faraday_error(url, e, options.merge(head: true))
  end

  def save_alm_data(id, options = { data: nil })
    data_rev = get_alm_rev(id)
    unless data_rev.blank?
      options[:data][:_id] = "#{id}"
      options[:data][:_rev] = data_rev
    end

    put_alm_data("#{couchdb_url}#{id}", options)
  end

  def put_alm_data(url, options = { data: nil })
    return nil unless options[:data] || Rails.env.test?
    conn = conn_json
    conn.options[:timeout] = DEFAULT_TIMEOUT
    response = conn.put url do |request|
      request.body = options[:data]
    end
    (response.body["ok"] ? response.body["rev"] : nil)
  rescue *SourceHelperExceptions => e
    rescue_faraday_error(url, e, options)
  end

  def remove_alm_data(id, data_rev)
    params = {'rev' => data_rev }
    delete_alm_data("#{couchdb_url}#{id}?#{params.to_query}")
  end

  def delete_alm_data(url, options={})
    return nil unless url != couchdb_url || Rails.env.test?
    response = conn_json.delete url
    (response.body["ok"] ? response.body["rev"] : nil)
  rescue *SourceHelperExceptions => e
    rescue_faraday_error(url, e, options)
  end

  def get_alm_database
    get_alm_data
  end

  def put_alm_database
    put_alm_data(couchdb_url)
    filter = Faraday::UploadIO.new('design_doc/filter.json', 'application/json')
    put_alm_data("#{couchdb_url}_design/filter", { data: filter })
  end

  def delete_alm_database
    delete_alm_data(couchdb_url)
  end

  def get_canonical_url(url, options = { timeout: 120 })
    conn = conn_html
    # disable ssl verification
    conn.options[:ssl] = { verify: false }

    conn.options[:timeout] = options[:timeout]
    response = conn.get url, {}, options[:headers]

    # Priority to find URL:
    # 1. <link rel=canonical />
    # 2. <meta property="og:url" />
    # 3. URL from header

    body = Nokogiri::HTML(response.body, nil, 'utf-8')
    body_url = body.at('link[rel="canonical"]')['href'] if body.at('link[rel="canonical"]')
    if !body_url && body.at('meta[property="og:url"]')
      body_url = body.at('meta[property="og:url"]')['content']
    end

    if body_url
      # remove percent encoding
      body_url = CGI.unescape(body_url)

      # make URL lowercase
      body_url = body_url.downcase

      # remove parameter used by IEEE
      body_url = body_url.sub("reload=true&", "")
    end

    url = response.env[:url].to_s
    if url
      # remove percent encoding
      url = CGI.unescape(url)

      # make URL lowercase
      url = url.downcase

      # remove jsessionid used by J2EE servers
      url = url.gsub(/(.*);jsessionid=.*/,'\1')

      # remove parameter used by IEEE
      url = url.sub("reload=true&", "")

      # remove parameter used by ScienceDirect
      url = url.sub("?via=ihub", "")
    end

    # get relative URL
    path = URI.split(url)[5]

    # we will raise an error if 1. or 2. doesn't match with 3. as this confuses Facebook
    if body_url.present? and ![url, path].include?(body_url)
      raise Faraday::Error::ClientError, "Canonical URL mismatch: #{body_url}"
    end

    url
  rescue *SourceHelperExceptions => e
    rescue_faraday_error(url, e, options.merge(doi_lookup: true))
  end

  def save_to_file(url, filename = "tmpdata", options = { timeout: DEFAULT_TIMEOUT })
    conn = conn_xml
    conn.basic_auth(options[:username], options[:password]) if options[:username]
    conn.options[:timeout] = options[:timeout]
    response = conn.get url

    File.open("#{Rails.root}/data/#{filename}", 'w') { |file| file.write(response.body) }
    filename
  rescue *SourceHelperExceptions => e
    rescue_faraday_error(url, e, options.merge(:xml => true))
  rescue => exception
    Alert.create(:exception => exception, :class_name => exception.class.to_s,
                        :message => exception.message,
                        :status => 500,
                        :source_id => options[:source_id])
    nil
  end

  def conn_json
    Faraday.new do |c|
      c.headers['Accept'] = 'application/json'
      c.headers['User-Agent'] = "#{CONFIG[:useragent]} - http://#{CONFIG[:hostname]}"
      c.use      Faraday::HttpCache, store: Rails.cache
      c.use      FaradayMiddleware::FollowRedirects, :limit => 10
      c.request  :multipart
      c.request  :json
      c.response :json, :content_type => /\bjson$/
      c.use      Faraday::Response::RaiseError
      c.adapter  Faraday.default_adapter
    end
  end

  def conn_xml
    Faraday.new do |c|
      c.headers['Accept'] = 'application/xml'
      c.headers['User-Agent'] = "#{CONFIG[:useragent]} - http://#{CONFIG[:hostname]}"
      c.use      Faraday::HttpCache, store: Rails.cache
      c.use      FaradayMiddleware::FollowRedirects, :limit => 10
      c.use      Faraday::Response::RaiseError
      c.adapter  Faraday.default_adapter
    end
  end

  def conn_html
    Faraday.new do |c|
      c.headers['Accept'] = 'text/html;charset=UTF-8'
      c.headers['Accept-Charset'] = 'UTF-8'
      c.headers['User-Agent'] = "#{CONFIG[:useragent]} - http://#{CONFIG[:hostname]}"
      c.use      Faraday::HttpCache, store: Rails.cache
      c.use      FaradayMiddleware::FollowRedirects, :limit => 10
      c.use      :cookie_jar
      c.use      Faraday::Response::RaiseError
      c.adapter  Faraday.default_adapter
    end
  end

  def couchdb_url
    CONFIG[:couchdb_url]
  end

  def rescue_faraday_error(url, error, options={})
    if error.kind_of?(Faraday::Error::ResourceNotFound)
      if error.response.blank? && error.response[:body].blank?
        nil
      elsif options[:doi_lookup]
        # we raise an error if a DOI can't be resolved
        # This is different from other 404 errors
        Alert.create(exception: error.exception,
                     class_name: error.class.to_s,
                     message: "DOI could not be resolved",
                     details: error.response[:body],
                     status: error.response[:status],
                     target_url: url)
        nil
      elsif options[:json]
        error.response[:body]
      elsif options[:xml]
        Nokogiri::XML(error.response[:body])
      elsif options[:html]
        error.response[:body]
      else
        error.response[:body]
      end
    # malformed JSON is treated as ResourceNotFound
    elsif error.message.include?("unexpected token")
      nil
    else
      details = nil

      if error.kind_of?(Faraday::Error::TimeoutError)
        status = 408
      elsif error.respond_to?('status')
        status = error[:status]
      elsif error.respond_to?('response') && error.response.present?
        status = error.response[:status]
        details = error.response[:body]
      else
        status = 400
      end

      if error.respond_to?('exception')
        exception = error.exception
      else
        exception = ""
      end

      class_name = error.class
      message = "#{error.message} for #{url}"

      case status
      when 400
        class_name = Net::HTTPBadRequest
      when 401
        class_name = Net::HTTPUnauthorized
      when 403
        class_name = Net::HTTPForbidden
      when 406
        class_name = Net::HTTPNotAcceptable
      when 408
        class_name = Net::HTTPRequestTimeOut
      when 409
        class_name = Net::HTTPConflict
        message = "#{error.message} with rev #{options[:data][:rev]}"
      when 417
        class_name = Net::HTTPExpectationFailed
      when 429
        class_name = Net::HTTPClientError
      when 500
        class_name = Net::HTTPInternalServerError
      when 502
        class_name = Net::HTTPBadGateway
      when 503
        class_name = Net::HTTPServiceUnavailable
      end

      Alert.create(exception: exception,
                   class_name: class_name.to_s,
                   message: message,
                   details: details,
                   status: status,
                   target_url: url,
                   source_id: options[:source_id])
      nil
    end
  end
end
