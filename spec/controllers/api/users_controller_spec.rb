require 'rails_helper'

describe Api::UsersController, type: :controller do
  describe 'GET show' do
    before :each do
      @user = create(:user, email: 'user@email.com', password: 'userpass')
      sign_in(@user, scope: :user)

      @user_empty = create(:user, email: 'empty@email.com', password: 'userpass')
      sign_in(@user_empty, scope: :user)

      @score1 = create(:score, user: @user, total_score: 79, played_at: '2021-05-20')
      @score2 = create(:score, user: @user, total_score: 99, played_at: '2021-06-20')
      @score3 = create(:score, user: @user, total_score: 68, played_at: '2021-06-13')
    end

    it 'should return user details with list of owned scores' do
      get :show, params: { id: @user.id }

      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body, symbolize_names: true)

      expect(response_hash[:user]).to eq @user.serialize

      expected_scores = [@score1.serialize, @score2.serialize, @score3.serialize].map do |score|
        score[:played_at] = score[:played_at].strftime('%Y-%m-%d')
        score
      end
      expect(response_hash[:scores]).to eq expected_scores
    end

    it 'should return user details and empty scores when scores not present' do
      get :show, params: { id: @user_empty.id }

      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body, symbolize_names: true)

      expect(response_hash[:user]).to eq @user_empty.serialize
      expect(response_hash[:scores]).to eq []
    end

    it 'should return user not found status when bad user id is passed' do
      get :show, params: { id: 100 }

      expect(response).to have_http_status(:not_found)
      response_hash = JSON.parse(response.body, symbolize_names: true)

      expect(response_hash).to eq errors: ['User not found']
    end
  end

  describe 'POST login' do
    before :each do
      create(:user, email: 'user@email.com', password: 'userpass')
    end

    it 'should return the token if valid username/password' do
      post :login, params: { email: 'user@email.com', password: 'userpass' }

      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body)
      user_data = response_hash['user']

      expect(user_data['token']).to be_present
    end

    it 'should return an error if invalid username/password' do
      post :login, params: { email: 'invalid', password: 'user' }

      expect(response).to have_http_status(401)
    end
  end
end
