module Search

logger = Chasm.logger

class SearchTerms
  CRITERIA = /([\w_\+\-~]*:["']*[\w\d\s\/\-=,_\.]+["']*)(?![\w:])/i

  attr_reader :terms

  def self.register_term(key, clazz)
    @terms ||= {}
    @terms[key.to_s] = clazz
    @terms[key.to_sym] = clazz
  end

  def self.term(key, value)
    if @terms.has_key?(key)
      @terms[key].new(key, value)
    else
      nil
    end
  end

  def self.parse_terms(criteria)
    terms = {}
    logger.debug("parsing terms: #{criteria}")
    captures = criteria.scan(CRITERIA)
    captures.flatten.compact.each do |capture|
      key, value = capture.strip.split(':')
      if terms.has_key?(key.to_sym)
        unless terms[key.to_sym].is_a?(Array)
          terms[key.to_sym] = [terms[key.to_sym]]
        end
        terms[key.to_sym] << value
      else
        terms[key.to_sym] = value
      end
    end
    SearchTerms.new(terms)
  end

  def initialize(terms = {})
    @terms = terms
    @term_objects = []
    @terms.each do |key, value|
      term = SearchTerms.term(key, value)
      if term
        @term_objects << term
      else
        logger.debug("search term #{key} not handled!")
      end
    end
  end

end

class IndexQuery
  attr_accessor :filter, :sort, :from, :size

  def initialize
    @sort = []
  end

  def to_hash(options = {})
    body = {}
    body[:query] = to_query_hash(options)
    body[:sort] = @sort if @sort
    body[:filter] = @filter if @filter
    body[:from] = @from if @from
    body[:size] = @size if @size
    body
  end
end

class IndexMatchAll < IndexQuery
  attr_accessor :boost

  def to_query_hash(options = {})
    hash = {match_all: {}}
    hash[:match_all][:boost] = @boost if @boost
    hash
  end
end

class IndexBoolQuery < IndexQuery
  attr_accessor :must, :must_not, :should, :minimum_should_match, :boost

  def initialize
    super
    @must = []
    @must_not = []
    @should = []
  end

  def to_query_hash(options = {})
    query = {}
    query[:bool] = {}
    query[:bool][:minimum_should_match] = @minimum_should_match if @minimum_should_match
    query[:bool][:boost] = @boost if @boost
    query[:bool][:must] = @must unless @must.empty?
    query[:bool][:must_not] = @must_not unless @must_not.empty?
    query[:bool][:should] = @should unless @should.empty?
    query
  end

  def empty?
    return false unless @must.empty?
    return false unless @must_not.empty?
    return false unless @should.empty?
    return true
  end
end

class MongoAggregationQuery
  attr_accessor :project, :match, :group, :sort, :geo_near, :limit, :skip, :unwind

  def initialize(body = {})
    @project = body['$project'] || {}
    @match = body['$match'] || {}
    @group = body['$group'] || {}
    @sort = body['$sort'] || {}
    @geo_near = body['$geoNear'] || {}
  end

  def and
    @match['$and'] ||= []
  end

  def or
    @match['$or'] ||= []
  end

  def to_hash(options = {})
    body = {}
    body['$project'] = @project unless @project.empty?
    body['$match'] = @match unless @match.empty?
    body['$group'] = @group unless @group.empty?
    body['$sort'] = @sort unless @sort.empty?
    body['$geoNear'] = @geo_near unless @geo_near.empty?
    body['$limit'] = @limit if @limit
    body['$skip'] = @skip if @skip
    body['$unwind'] = @unwind if @unwind
    body
  end

  def empty?
    return false unless @match.empty?
    return true
  end
end

class Term
  attr_reader :key, :value

  def initialize(key, value)
    @key = key
    @value = value
  end

  def words
    if @value.is_a?(Array)
      @value
    else
      "#{@value}".split(/[\s,]+/)
    end
  end

  def value
    if @value.is_a?(Array)
      @value.first
    else
      @value
    end
  end

  def numeric_range?
    value =~ /(\d+)-(\d+)/
  end

  def numeric_range
    return $1.to_i..$2.to_i if value =~ /(\d+)-(\d+)/
    return nil
  end
end

end
