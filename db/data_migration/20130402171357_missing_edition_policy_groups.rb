# Assumes the last non-empty set of ids is the best collection to use for populating the missing EditionPolicyGroups

puts "EditionPolicyGroups: #{EditionPolicyGroup.all.count}"

edition_policy_groups_by_document = EditionPolicyGroup.all.group_by {|x| Edition.unscoped.find_by_id(x.edition_id).document_id }
documents_which_have_ever_had_a_policy_group = Document.find(edition_policy_groups_by_document.keys).select(&:published?)

documents_which_have_ever_had_a_policy_group.each do |doc|

  edition_policy_groups_for_each_edition = doc.editions.map(&:edition_policy_groups)

  ids_at_index_to_update = []
  edition_policy_groups_for_each_edition.each_with_index {|epg, i| ids_at_index_to_update << i if epg.blank? }

  edition_ids = doc.editions.map(&:id)
  edition_ids_to_update = ids_at_index_to_update.map { |i| edition_ids[i] }

  last_known_good_set_of_policy_group_ids = edition_policy_groups_for_each_edition.reject(&:blank?).last.map(&:policy_group_id)

  edition_ids_to_update.each do |e_id|
    last_known_good_set_of_policy_group_ids.each do |pg_id|
      EditionPolicyGroup.create edition_id: e_id, policy_group_id: pg_id
    end
  end
end

puts "After update..."
puts "EditionPolicyGroups: #{EditionPolicyGroup.all.count}"
