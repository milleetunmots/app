require 'rails_helper'
require 'rake'

RSpec.describe 'admin_users:audit_weak_passwords' do
  before(:all) do
    Rake.application.rake_require('tasks/audit_weak_passwords', [Rails.root.join('lib').to_s])
    Rake::Task.define_task(:environment)
  end

  before(:each) { Rake::Task['admin_users:audit_weak_passwords'].reenable }

  it 'imprime le rapport pour un compte compromis' do
    FactoryBot.create(:admin_user, name: 'Marie Curie', email: 'mcurie@1001mots.fr', password: 'Mariecurie2024!')

    expect { Rake::Task['admin_users:audit_weak_passwords'].invoke }
      .to output(/comptes compromis/).to_stdout
  end
end
