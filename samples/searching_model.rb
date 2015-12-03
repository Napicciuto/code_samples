class Mod < ActiveRecord::Base
  serialize :tags, Array

  SEARCHABLES = %w(name description tags)
  MODSHOP_SEARCHABLES = %w(username shop_name) 

  belongs_to :user
  has_and_belongs_to_many :categories
  has_and_belongs_to_many :users
  has_many :categories_mods
  has_many :mod_files, dependent: :destroy
  accepts_nested_attributes_for :mod_files, allow_destroy: true, reject_if: proc { |attributes| attributes['id'].blank? }

  validates :user_id, :name, :main_image, presence: true
  validates :name, length: { maximum: 65 }
  validates :description, length: { maximum: 140 }

  mount_uploader :main_image, ModImageUploader

 default_scope { order('created_at DESC') } 

 self.per_page = 12

  class << self

    def list_tags
      flattened_tags.uniq
    end

    def tag_filters
      popular_tag.first(20)
    end

    def popular_tag
      flattened_tags.group_by { |x| x }.sort_by { |k, v| v.length }.map(&:first).reverse
    end

    def top_envies
      all.sort_by {|x| x.users.count}.reverse
    end

    def flattened_tags
      all.map(&:tags).flatten
    end

    def search_results(search, text_search=search[:text_search], tags=search[:tags]||[], categories=search[:categories]||[])
      if text_search.blank? && tags.blank? && categories.blank?
        all
      else
	mod_search(tags, 'mods.tags').category_filter(categories).result_collection(sanitize_search_terms(text_search))
      end
    end

    def result_collection(search_terms)
      (mod_search_terms(search_terms) + mod_user_search(search_terms) + product_search(search_terms)).flatten.uniq
    end

    def sanitize_search_terms(search_terms)
      search_terms.to_s.downcase.split(" ")
    end

    def mod_search_terms(search_terms)
      SEARCHABLES.map { |term| mod_search(search_terms, "mods.#{term}") }
    end

    def product_search(search_terms)
      joins_search(:mod_files, search_terms, 'products_used')
    end

    def category_filter(categories)
      categories.blank? ? all : joins_search(:categories, categories, 'name')
    end

    def mod_user_search(search_terms)
      MODSHOP_SEARCHABLES.map { |column| joins_search(:user, search_terms, column, 'users') }
    end

    def joins_search(table, terms, column, alt_table="")
      query_table = alt_table.blank? ? "#{table.to_s}" : alt_table
      joins(table).mod_search(terms, "#{query_table}.#{column}")
    end

    def mod_search(search_terms, column)
      search_terms.blank? ? all : where("lower(#{column}) ~* ?" , search_terms.join('|'))
    end
  end

  def categories_by_name
    first_category.try(:name) || "none"
  end

  def categories_count
    categories.count
  end

  def first_category
    categories.try(:first)
  end

  def file_list_by_type(file_type)
    mod_files.select { |file| file.content_type.include?(file_type) }
  end
end

