GOOGLE_NEWS_URL_1 = 'http://news.google.ca/news?pz=1&cf=all&ned=ca&hl=en&as_maxm=3&q='
GOOGLE_NEWS_URL_2 = '&as_qdr=a&as_drrb=q&as_mind=25&as_minm=2&cf=all&as_maxd=27&scoring=n&output=rss'

class InfoController < ApplicationController
  
  before_filter :authenticate, :only => [:questionnaire_emails]
  caches_page :index, :mayor, :council, :all_council, :trustee_candidate, :ward, :school_ward, :school_board, :candidate, :incumbents
  
  def index
    @days_until_election = (Date.parse("2010 October 27") - Time.zone.today).to_i
    @meta_description = "Get to know your mayoral, city council and school trustee candidates for the upcoming Winnipeg civic election."
  end
  def mayor
    @show_feedback = true
    @ward = Ward.mayoral.with_candidates.first
    @mentions = Mention.all( :select => "mentions.news_article_id", :conditions => ["candidate_id IN (?)",@ward.candidates] )
    @news_articles = NewsArticle.all( :include => {:mentions => [:candidate]}, :conditions => ["id IN (#{@mentions.map(&:news_article_id).join(",")})"], :order => "pubdate DESC", :limit => 10)
    @title = 'Mayoral Candidates'
    @atom_auto_discovery = @ward.rss_url
  end
  def council
    @title = 'Council Wards'
    @wards = Ward.council.all(:order => 'wards.name')
  end
  def all_council
    @show_feedback = true
    @wards = Ward.council.with_candidates.all(:order => 'wards.name')
    @title = 'City Councillor Candidates'
    @wards_title = 'All Electoral Wards'
  end
  def trustee_candidate
    @show_feedback = true
    @candidate_name = TrusteeCandidate.url_to_candidate(params[:candidate_name])
    @title = @candidate_name
    @candidate = TrusteeCandidate.by_name(@candidate_name).with_division_ward.first
  end
  def ward
    @show_feedback = true
    @ward_name = Ward.url_to_ward(params[:ward_name])
    @ward = Ward.with_candidates.first( :conditions => ["wards.name = ?", @ward_name] )
    @mentions = Mention.all( :select => "mentions.news_article_id", :conditions => ["candidate_id IN (?)",@ward.candidates] )
    @news_articles = NewsArticle.all( :include => {:mentions => [:candidate]}, :conditions => ["id IN (#{@mentions.map(&:news_article_id).join(",")})"], :order => "pubdate DESC", :limit => 10)
    @atom_auto_discovery = @ward.rss_url
  end
  def school_ward
    @show_feedback = true
    @school_ward_name = SchoolWard.url_to_ward(params[:ward_name])
    @school_division_name = SchoolDivision.url_to_ward( params[:division_name])
    @school_ward = SchoolWard.first(:include => [:trustee_candidates, :school_division] , :conditions => ["school_wards.name = ? and school_divisions.name = ?", @school_ward_name, @school_division_name] )
  end
  def school_board
    @title = 'School Division Wards'
    @school_divisions = SchoolDivision.all(:include => [:school_wards], :order =>"school_divisions.name")
  end
  def candidate
    @show_feedback = true
    @page_num = params[:page_id] || '1'
    
    @candidate_name = Candidate.url_to_candidate(params[:candidate_name])
    @title = @candidate_name
    @candidate = Candidate.by_name(@candidate_name).with_ward.first
    @atom_auto_discovery = @candidate.rss_url
    
    @mentions = Mention.with_related_approved_news.by_name(@candidate.id)
    @mentions.per_page = 7
    
    @current_mentions_page = @mentions.pages.find(@page_num)
    @current_mentions_page.paginator.set_path { |page| paged_candidate_path(page, params[:candidate_name]) + '#related_news' }
    @mentions_by_date = @current_mentions_page.mentions.group_by{ |mention| mention.news_article.pretty_date }
  end
  def incumbents
    @title = 'Incumbents'
    # Quicker here not to eager load the mentions 'cause we just need their count.
    # Is there any way to eager load an association count? I guess we could use counter caching.
    # Tried to use a :select to specify count, but they are ignored when using :include. Boo.
    @mayor = Candidate.incumbent.with_ward.first(:conditions => "wards.ward_type ='Mayoral'")
    @incumbents = Candidate.incumbent.with_ward.all(:conditions => "wards.ward_type ='Civic'", :order => 'wards.name') # Previously :order => Candidate.db_random but js handles that now. see:main.js
    @school_divisions = SchoolDivision.all(:include => {:school_wards => :trustee_candidates}, :order => 'school_divisions.name, school_wards.name', :conditions => 'trustee_candidates.incumbent_since = 2006')
  end
  def questionnaire_emails
    @candidates = TrusteeCandidate.all(:include => 'school_ward', :order => 'name')
    #@candidates = Candidate.all(:include => 'ward', :order => 'name')
  end
end
