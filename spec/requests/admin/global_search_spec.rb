require 'rails_helper'

RSpec.describe 'Admin global search', type: :request do
  let!(:parent) { FactoryBot.create(:parent, first_name: 'Amina', last_name: 'Diallo', phone_number: '0668021234') }

  before { sign_in FactoryBot.create(:admin_user, user_role: 'super_admin') }

  def search(term)
    get '/admin/search', params: { term: term }
    JSON.parse(response.body)['results']
  end

  it 'trouve un parent par son numéro national sans séparateur' do
    expect(search('0668021234').map { |r| r['type'] }).to include('Parent')
  end

  it 'trouve un parent par son numéro national avec des espaces' do
    expect(search('06 68 02 12 34').map { |r| r['type'] }).to include('Parent')
  end

  it 'trouve un parent par son numéro national avec des points ou des tirets' do
    expect(search('06.68.02.12.34').map { |r| r['type'] }).to include('Parent')
    expect(search('06-68-02-12-34').map { |r| r['type'] }).to include('Parent')
  end

  it 'trouve un parent par son numéro au format international' do
    expect(search('+33 6 68 02 12 34').map { |r| r['type'] }).to include('Parent')
    expect(search('0033668021234').map { |r| r['type'] }).to include('Parent')
  end

  it 'trouve un parent par un numéro partiel espacé' do
    expect(search('06 68 02').map { |r| r['type'] }).to include('Parent')
  end

  it 'trouve un parent par un numéro partiel au format international' do
    expect(search('+33 6 68 02').map { |r| r['type'] }).to include('Parent')
  end

  it 'ne trouve rien pour un autre numéro' do
    expect(search('07 11 22 33 44')).to be_empty
  end

  it 'continue de chercher par nom' do
    expect(search('Diallo').map { |r| r['type'] }).to include('Parent')
  end
end