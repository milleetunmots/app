require 'rails_helper'

# Parcours réel d'un livre « Non envoyé » : arrêt pour numéro erroné, attribution du livre
# du module suivant, reprise de l'accompagnement, puis import du renvoi SAV.
RSpec.describe 'Livre « Non envoyé » : numéro erroné → attribution → reprise → renvoi SAV' do
  let!(:group) { FactoryBot.create(:group, started_at: 8.weeks.ago.prev_occurring(:monday), ended_at: 8.weeks.from_now) }
  let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child_support) { child.child_support }
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) { FactoryBot.create(:support_module, book: book) }
  let!(:children_support_module) do
    FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
  end
  let!(:supporter) { FactoryBot.create(:admin_user, user_role: 'contributor') }

  let!(:next_resend_date) { BookShipmentDate.create!(date: Date.current + 10.days).date }
  # la validation refuse une date passée à la création : on la recale ensuite
  let!(:last_shipment_date) do
    BookShipmentDate.create!(date: Date.current + 1.day).tap { |shipment| shipment.update_column(:date, Date.current - 45.days) }.date
  end

  def pending_book_resend_date
    child_support.reload.pending_book_resend_date(child.id)
  end

  def stop_for_unassigned_number
    child_support.update!(call0_status: 'Numéro erroné')
    Child::StopUnassignedNumberService.new.call
  end

  def attribute_books
    ChildrenSupportModule::SaveBookFromSupportModuleService.new(group_id: group.id).call
  end

  def restart_for_unreachable_number
    ChildSupport::CallerRestartSupportService.new(supporter.id, child_support.id, ['unreachable_number'], nil).call
  end

  def import_sav_resend(row)
    file = Tempfile.new(['sav_import', '.csv'])
    file.write("Date d'envoi fichier SAV YLS,Children Support Modules → ID,Book condition\n#{row}\n")
    file.rewind
    Book::SavImportService.new(csv_file: file).call
  end

  it "trace le livre non envoyé, l'annonce au renvoi après la reprise, puis enregistre le renvoi" do
    stop_for_unassigned_number
    expect(child.reload.group_status).to eq('stopped')

    attribute_books
    children_support_module.reload
    expect(children_support_module.book_id).to eq(book.id)
    expect(children_support_module.book_condition).to eq('not_sent')
    expect(child_support.reload.address_suspected_invalid_at).to be_nil
    expect(pending_book_resend_date).to be_nil

    expect(restart_for_unreachable_number.error).to be_nil
    expect(child.reload.group_status).to eq('active')
    expect(pending_book_resend_date).to eq(next_resend_date)

    result = import_sav_resend("#{next_resend_date.strftime('%d/%m/%Y')},#{children_support_module.id},not_sent")
    expect(result.errors).to be_empty
    expect(children_support_module.reload.book_resent_on).to eq(next_resend_date)
    expect(children_support_module.book_condition).to eq('not_sent')
    expect(pending_book_resend_date).to be_nil
  end

  it "n'annonce pas de renvoi après la reprise quand le « Non envoyé » date d'avant le dernier envoi SAV" do
    stop_for_unassigned_number
    attribute_books
    children_support_module.reload.update_column(:book_condition_changed_at, last_shipment_date - 1.day)

    restart_for_unreachable_number

    expect(child.reload.group_status).to eq('active')
    expect(pending_book_resend_date).to be_nil
  end
end
