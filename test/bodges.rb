module FactoryGirlInterceptor

  include Factory::Syntax::Methods

  def attributes_for(name, overrides = {}, &block)
    super(*adapt(name, overrides), &block)
  end

  def build(name, overrides = {}, &block)
    super(*adapt(name, overrides), &block)
  end

  def create(name, overrides = {}, &block)
    super(*adapt(name, overrides), &block)
  end

  def adapt(name, overrides = {})
    new_name, new_overrides = name, overrides.dup
    if [
         :document_country,
         :supporting_page,
         :editorial_remark,
         :recent_document_opening,
         :image, :fact_check_request,
         :document_relation,
         :document_organisation,
         :document_attachment
        ].include?(name) && new_overrides.has_key?(:document)
      new_overrides[:edition] = new_overrides.delete(:document)
    elsif [
        :ministerial_role,
        :organisation,
        :country,
        :ministerial_department
      ].include?(name) && new_overrides.has_key?(:documents)
      new_overrides[:editions] = new_overrides.delete(:documents)
    end
    [new_name, new_overrides]
  end
end

class DocIdentity < ActiveRecord::Base
  alias_method :published_document, :published_edition
end

class SupportingPage < ActiveRecord::Base
  alias_method :document, :edition
end

class DocumentRelation < ActiveRecord::Base
  alias_method :document, :edition
end

class Organisation < ActiveRecord::Base
  alias_method :published_documents, :published_editions
end
