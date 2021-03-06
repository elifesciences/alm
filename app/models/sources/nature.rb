# encoding: UTF-8

# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2012 by Public Library of Science, a non-profit corporation
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

class Nature < Source
  def get_events(result)
    Array(result['data']).map do |item|
      item.extend Hashie::Extensions::DeepFetch
      event_time = get_iso8601_from_time(item['post']['created_at'])
      url = item['post']['url']
      url = "http://#{url}" unless url.start_with?("http://")

      { event: item['post'],
        event_time: event_time,
        event_url: url,

        # the rest is CSL (citation style language)
        event_csl: {
          'author' => '',
          'title' => item.deep_fetch('post', 'title') { '' },
          'container-title' => item.deep_fetch('post', 'blog', 'title') { '' },
          'issued' => get_date_parts(event_time),
          'url' => url,
          'type' => 'post' }
      }
    end
  end

  def config_fields
    [:url]
  end

  def url
    config.url || "http://blogs.nature.com/posts.json?doi=%{doi}"
  end

  def staleness_year
    config.staleness_year || 1.month
  end

  def rate_limiting
    config.rate_limiting || 5000
  end
end
