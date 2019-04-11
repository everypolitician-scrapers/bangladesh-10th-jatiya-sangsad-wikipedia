#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require_relative 'lib/remove_notes'
require_relative 'lib/unspan_all_tables'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links
  decorator RemoveNotes

  field :members do
    member_items.map { |tr| fragment(tr => MemberItem).to_h }
  end

  private

  def member_items
    noko.xpath('//table[.//th[contains(.,"Constituency")]]//tr[td]')
  end
end

class MemberItem < Scraped::HTML
  field :name do
    tds[1].text.tidy
  end

  field :id do
    tds[1].xpath('.//a/@wikidata').text
  end

  field :area do
    tds[2].text.tidy
  end

  field :area_id do
    tds[2].xpath('.//a/@wikidata').text
  end

  field :party do
    tds[3].text.tidy
  end

  field :party_id do
    tds[3].xpath('a/@wikidata').text
  end

  private

  def tds
    noko.css('td')
  end
end

url = 'https://en.wikipedia.org/wiki/List_of_members_of_the_10th_Jatiya_Sangsad'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name area party])
