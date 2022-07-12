require 'rails_helper'

describe Api::ScoresController, type: :request do
  before :each do
    @user1 = create(:user, name: 'User1', email: 'user1@email.com', password: 'userpass')
    user2 = create(:user, name: 'User2', email: 'user2@email.com', password: 'userpass')
    sign_in(@user1, scope: :user)

    @score1 = create(:score, user: @user1, total_score: 79, played_at: '2021-05-20')
    @score2 = create(:score, user: user2, total_score: 99, played_at: '2021-06-20')
    @score3 = create(:score, user: user2, total_score: 68, played_at: '2021-06-13')
  end

  describe 'GET feed' do
    it 'should return the scores ordered by played at if valid username/password' do
      get api_feed_path

      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body)
      scores = response_hash['scores']

      expect(scores.size).to eq 3
      expect(scores[0]['user_name']).to eq 'User2'
      expect(scores[0]['total_score']).to eq 99
      expect(scores[0]['played_at']).to eq '2021-06-20'
      expect(scores[1]['total_score']).to eq 68
      expect(scores[2]['total_score']).to eq 79
    end

    it 'should return the latest 25 scores even if more scores are in present' do
      expected_scores = [@score1.serialize, @score2.serialize, @score3.serialize]
      # generate 50 new entries in the score table
      (1..50).each { |i|
        score = create(:score, user: @user1, total_score: rand(54..120), played_at: Date.today - i.day).serialize
        expected_scores.append score
      }

      # sort the expected scores decreasingly by played_at
      expected_scores = expected_scores.sort_by { |item| item[:played_at] }.reverse!

      # convert the date to string
      expected_scores = expected_scores.map do |score|
        score[:played_at] = score[:played_at].strftime('%Y-%m-%d')
        score
      end

      get api_feed_path

      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body, symbolize_names: true)
      scores = response_hash[:scores]

      expect(scores.size).to eq 25
      expect(scores).to eq expected_scores[0, 25]
    end

    it 'should return all scores if less than 25' do
      expected_scores = [@score1.serialize, @score2.serialize, @score3.serialize]
      # generate 50 new entries in the score table
      (1..10).each { |i|
        score = create(:score, user: @user1, total_score: rand(54..120), played_at: Date.today - i.day).serialize
        expected_scores.append score
      }

      # sort the expected scores decreasingly by played_at
      expected_scores = expected_scores.sort_by { |item| item[:played_at] }.reverse!

      # convert the date to string
      expected_scores = expected_scores.map do |score|
        score[:played_at] = score[:played_at].strftime('%Y-%m-%d')
        score
      end

      get api_feed_path

      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body, symbolize_names: true)
      scores = response_hash[:scores]

      expect(scores.size).to eq 13
      expect(scores).to eq expected_scores[0, 13]
    end

  end

  describe 'POST create' do
    it 'should save and return the new score if valid parameters' do
      score_count = Score.count

      post api_scores_path, params: { score: { total_score: 79, played_at: '2021-06-29' } }

      expect(response).to have_http_status(:ok)
      expect(Score.count).to eq score_count + 1
      response_hash = JSON.parse(response.body)

      score_hash = response_hash['score']
      expect(score_hash['user_name']).to eq 'User1'
      expect(score_hash['total_score']).to eq 79
      expect(score_hash['played_at']).to eq '2021-06-29'

      score = Score.last
      expect(score.user_id).to eq @user1.id
      expect(score.total_score).to eq 79
      expect(score.played_at.to_s).to eq '2021-06-29'
    end

    it 'should return a validation error if score is played in the future' do
      score_count = Score.count

      post api_scores_path, params: { score: { total_score: 79, played_at: '2090-06-29' } }

      expect(response).not_to have_http_status(:ok)
      expect(Score.count).to eq score_count
    end

    it 'should return a validation error if score value is too low' do
      score_count = Score.count

      post api_scores_path, params: { score: { total_score: 10, played_at: '2021-06-29' } }

      expect(response).not_to have_http_status(:ok)
      expect(Score.count).to eq score_count
    end
  end

  describe 'DELETE destroy' do
    it 'should delete the score' do
      score_count = Score.count

      delete api_score_path(@score1.id)

      expect(response).to have_http_status(:ok)
      expect(Score.count).to eq score_count - 1
      response_hash = JSON.parse(response.body)

      score_hash = response_hash['score']
      expect(score_hash['user_name']).to eq 'User1'
      expect(score_hash['total_score']).to eq 79
      expect(score_hash['played_at']).to eq '2021-05-20'
    end

    context 'with error page rendering turned on', with_errors_rendered: true do
      it 'should return error if invalid ID' do
        score_count = Score.count

        delete api_score_path('123456')

        expect(response).not_to have_http_status(:ok)
        expect(Score.count).to eq score_count
      end
    end

    it 'should return error if the score belongs to another user' do
      score_count = Score.count

      delete api_score_path(@score2.id)

      expect(response).not_to have_http_status(:ok)
      expect(Score.count).to eq score_count
    end
  end
end
