class NewsArticlesController < ApplicationController
  before_filter :authenticate, :except => :latest
  
  def index
    @news_articles_new = NewsArticle.unset.with_mentions.desc
    @news_articles_approved = NewsArticle.approved.with_mentions.desc
    @news_articles_rejected = NewsArticle.rejected.with_mentions.desc
  end
  
  def show
    @news_article = NewsArticle.find(params[:id], :include => :candidates)
  end
  
  def new
    @news_article = NewsArticle.new
  end
  
  def create
    @news_article = NewsArticle.new(params[:news_article])
    if @news_article.save
      flash[:notice] = "Successfully created news article."
      redirect_to @news_article
    else
      render :action => 'new'
    end
  end
  
  def edit
    @news_article = NewsArticle.find(params[:id], :include => :candidates)
  end
  
  def update
    params[:news_article][:candidate_ids] ||= []
    @news_article = NewsArticle.find(params[:id], :include => :candidates)
    if @news_article.update_attributes(params[:news_article])
      flash[:notice] = "Successfully updated news article."
      redirect_to @news_article
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @news_article = NewsArticle.find(params[:id])
    @news_article.destroy
    flash[:notice] = "Successfully destroyed news article."
    redirect_to news_articles_url
  end
  
  def approve
    @news_article = NewsArticle.find(params[:id])
    @news_article.moderation = 'approved'
    if @news_article.save
      flash[:notice] = 'Successfully approved news article.'
    else
      flash[:error] = 'Error approving news article.'
    end
    redirect_to news_articles_url
  end
  
  def reject
    @news_article = NewsArticle.find(params[:id])
    @news_article.moderation = 'rejected'
    if @news_article.save
      flash[:notice] = 'Successfully rejected news article.'
    else
      flash[:error] = 'Error rejecting news article.'
    end
    redirect_to news_articles_url
  end
  
  def latest
    @title = 'Latest Election News'
    page_num = params[:page_id] || 1
    
    articles = NewsArticle.approved.desc
    articles.per_page = 15
    
    @current_page = articles.pages.find(page_num)
    @current_page.paginator.set_path { |page|  latest_page_news_articles_path(page) }
    
    @current_page_by_date = @current_page.news_articles.group_by(&:pretty_date)
    
    @atom_auto_discovery = latest_feed_path(:atom)
  end
 end
