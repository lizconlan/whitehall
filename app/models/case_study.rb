class CaseStudy < Edition
  include Edition::Images
  include Edition::RelatedPolicies
  include Edition::FactCheckable
  include Edition::FirstImagePulledOut
  include Edition::DocumentSeries
  include Edition::WorldLocations
  include Edition::WorldwideOrganisations
  include Edition::WorldwidePriorities

  def display_type_key
    "case_study"
  end

  def search_format_types
    super + [CaseStudy.search_format_type]
  end

  def translatable?
    true
  end
end
