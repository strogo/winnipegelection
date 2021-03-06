class SchoolWard < ActiveRecord::Base
  belongs_to :school_division
  has_many :trustee_candidates
  
  attr_accessible :name, :description, :school_division_id, :seats, :image, :delete_image
  
  has_attached_file :image, :styles => { :large => "300x300>", :medium => "240x240>", :small => "120x120>", :tiny => "60x60>" },
                    :url  => "/uploads/school_ward_image/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/uploads/school_ward_image/:id/:style/:basename.:extension"
                    
  # Virtual Attribute for image deletion.
  def delete_image=(value)
    self.image = nil if (!value.to_i.zero?)
  end
  
  def delete_image
    false
  end
  
  def name_with_division
    "#{school_division.name} - #{name}"
  end
  
  def ward_url
    "/school_ward/#{school_division.division_url}/"+self.name.sub(/ St\./,' St').gsub(' ','_')
  end
  
  def rss_url
    false
  end
  
  def self.url_to_ward(url)
    url.sub(/_St_/,'_St._').gsub('_',' ')
  end
  
  def candidates
    trustee_candidates
  end
end
