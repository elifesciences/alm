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
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'net/http'
require 'uri'

module Networkable
  extend ActiveSupport::Concern

  included do

    def get_result(url, options = { content_type: 'json' })
      conn = faraday_conn(options[:content_type])
      conn.basic_auth(options[:username], options[:password]) if options[:username]
      conn.authorization :Bearer, options[:bearer] if options[:bearer]
      conn.options[:timeout] = options[:timeout] || DEFAULT_TIMEOUT
      if options[:data]
        response = conn.post url, {}, options[:headers] do |request|
          request.body = options[:data]
        end
      else
        response = conn.get url, {}, options[:headers]
      end
      # parsing by content type is not reliable, so we check the response format
      if is_json?(response.body)
        JSON.parse(response.body)
      elsif is_xml?(response.body)
        Hash.from_xml(response.body)
      else
        response.body
      end
    rescue *NETWORKABLE_EXCEPTIONS => e
      rescue_faraday_error(url, e, options)
    end

    def save_to_file(url, filename = "tmpdata", options = { content_type: 'xml' })
      conn = faraday_conn(options[:content_type])
      conn.basic_auth(options[:username], options[:password]) if options[:username]
      conn.options[:timeout] = options[:timeout] || DEFAULT_TIMEOUT
      response = conn.get url

      File.open("#{Rails.root}/data/#{filename}", 'w') { |file| file.write(response.body) }
      filename
    rescue *NETWORKABLE_EXCEPTIONS => e
      rescue_faraday_error(url, e, options)
    rescue => exception
      Alert.create(:exception => exception,
                   :class_name => exception.class.to_s,
                   :message => exception.message,
                   :status => 500,
                   :level => Alert::FATAL,
                   :source_id => options[:source_id])
      nil
    end

    def read_from_file(filename = "tmpdata", options = { content_type: 'xml' })
      file = File.open("#{Rails.root}/data/#{filename}", 'r') { |f| f.read }
      Hash.from_xml(file)
    rescue *NETWORKABLE_EXCEPTIONS => e
      rescue_faraday_error(url, e, options)
    rescue => exception
      Alert.create(:exception => exception,
                   :class_name => exception.class.to_s,
                   :message => exception.message,
                   :status => 500,
                   :level => Alert::FATAL,
                   :source_id => options[:source_id])
      nil
    end

    def faraday_conn(content_type = 'json')
      accept_header =
        case content_type
        when 'html' then 'text/html'
        when 'xml' then 'application/xml'
        else 'application/json'
        end

      Faraday.new do |c|
        c.headers['Accept'] = accept_header
        c.headers['User-Agent'] = "#{CONFIG[:useragent]} #{Rails.application.config.version} - http://#{CONFIG[:public_server]}"
        c.use      FaradayMiddleware::FollowRedirects, :limit => 10, :cookie => :all
        c.request  :multipart
        c.request  :json if accept_header == 'application/json'
        c.use      Faraday::Response::RaiseError
        c.adapter  Faraday.default_adapter
      end
    end

    def rescue_faraday_error(url, error, options={})
      if error.kind_of?(Faraday::Error::ResourceNotFound)
        status = 404
        if error.response.blank? && error.response[:body].blank?
          { error: "resource not found", status: status }
        # we raise an error if we find a canonical URL mismatch
        elsif options[:doi_mismatch]
          Alert.create(exception: error.exception,
                       class_name: error.class.to_s,
                       message: error.response[:message],
                       details: error.response[:body],
                       status: status,
                       target_url: url)
          { error: error.response[:message], status: status }
        # we raise an error if a DOI can't be resolved
        elsif options[:doi_lookup]
          Alert.create(exception: error.exception,
                       class_name: error.class.to_s,
                       message: "DOI could not be resolved",
                       details: error.response[:body],
                       status: status,
                       target_url: url)
          { error: "DOI could not be resolved", status: status }
        else
          error = parse_error_response(error.response[:body])
          { error: error, status: status }
        end
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

        class_name = class_by_status(status) || error.class
        level = level_by_status(status)

        message = parse_error_response(error.message)
        message = "#{message} for #{url}"
        message = "#{message} with rev #{options[:data][:rev]}" if class_name == Net::HTTPConflict

        Alert.create(exception: exception,
                     class_name: class_name.to_s,
                     message: message,
                     details: details,
                     status: status,
                     target_url: url,
                     level: level,
                     source_id: options[:source_id])
        { error: message, status: status }
      end
    end

    def class_by_status(status)
      class_name =
        case status
        when 400 then Net::HTTPBadRequest
        when 401 then Net::HTTPUnauthorized
        when 403 then Net::HTTPForbidden
        when 404 then Net::HTTPNotFound
        when 406 then Net::HTTPNotAcceptable
        when 408 then Net::HTTPRequestTimeOut
        when 409 then Net::HTTPConflict
        when 417 then Net::HTTPExpectationFailed
        when 429 then Net::HTTPClientError
        when 500 then Net::HTTPInternalServerError
        when 502 then Net::HTTPBadGateway
        when 503 then Net::HTTPServiceUnavailable
        else nil
        end
    end

    def level_by_status(status)
      level =
        case status
        # temporary network problems should be WARN not ERROR
        when 408, 502, 503, 504 then 2
        else 3
        end
    end

    def parse_error_response(string)
      if is_json?(string)
        string = JSON.parse(string)
      elsif is_xml?(string)
        string = Hash.from_xml(string)
      end
      string = string['error'] if string.is_a?(Hash) && string['error']
      string
    end

    def is_xml?(string)
      Nokogiri::XML(string).errors.empty?
    end

    def is_json?(string)
      JSON.parse(string)
    rescue JSON::ParserError
      false
    end
  end
end
