class Ward < ActiveRecord::Base
  WARD_TYPES = ['Civic','Mayoral']
  
  has_many :candidates # previous ordered random. js handles that now. see:main.js
  
  validates_presence_of :name, :ward_type
  validates_inclusion_of :ward_type, :in => WARD_TYPES, :message => "must be: #{WARD_TYPES.join(', ')}"
  
  attr_accessible :name, :pdf_map_url, :ward_type, :image, :stats, :past_votes, :delete_image
  
  has_attached_file :image, :styles => { :large => "300x300>", :medium => "240x240>", :small => "120x120>", :tiny => "60x60>" },
                    :url  => "/uploads/ward_image/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/uploads/ward_image/:id/:style/:basename.:extension"
  
  named_scope :council, :conditions => "ward_type = 'Civic'"
  named_scope :mayoral, :conditions => "ward_type = 'Mayoral'"
  named_scope :with_candidates, :include => {:candidates => [:mentions]} # previous ordered random. js handles that now. see:main.js
  
  def ward_url
    "/ward/"+self.name.sub(/^St\./,'St').gsub(' ','_')
  end
  
  def rss_url
    "/feeds/ward/#{self.name.sub(/^St\./,'St').gsub(' ','_')}.atom"
  end
  
  def self.url_to_ward(url)
    url.sub(/^St/,'St.').gsub('_',' ')
  end
  
  # Virtual Attribute for image deletion.
  def delete_image=(value)
    self.image = nil if (!value.to_i.zero?)
  end
  
  def delete_image
    false
  end
end
