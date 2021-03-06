class AnswersController < ApplicationController
  # before_actionでshowアクションの先にset_searchメソッドを呼び出さないとエラーになる
  before_action :set_search

  def show
    # answersのviewへ渡すようにquestions_controllerで作成したセッションパラメーターをインスタンス変数に格納する
    @rent_budget = session[:rent_budget].delete("^0-9").to_i # 〇〇万円以下の数値だけを格納する
    @floor_plan = session[:floor_plan]
    @prefecture_to_live = session[:prefecture_to_live]
    # 以下、値を"必須" = "有り"、"必須ではない" = "無し"に変換する
    # 三項演算子を使ってみる'条件 ? 式1 : 式2' true => 式1、false => 式2を実行
    @gym = session[:gym] == "必須" ? "有り" : ["有り", "無し"]
    @starbucks_coffee = session[:starbucks_coffee] == "必須" ? "有り" : ["有り", "無し"]
    @mcdonalds = session[:mcdonalds] == "必須" ? "有り" : ["有り", "無し"]
    @ohsho = session[:ohsho] == "必須" ? "有り" : ["有り", "無し"]
    @supermarket = session[:supermarket] == "必須" ? "有り" : ["有り", "無し"]
    @large_park = session[:large_park] == "必須" ? "有り" : ["有り", "無し"]
    @library = session[:library] == "必須" ? "有り" : ["有り", "無し"]
    @spa = session[:spa] == "必須" ? "有り" : ["有り", "無し"]
    # show_4の住みたいエリアの入力から条件分岐でスクレイピングのメソッドを始動する
    # 格納した値をmodelへ渡す為にグローバル変数を設定
    $destination_1 = session[:destination_1]
    $transit_time_1 = session[:transit_time_1]
    $destination_2 = session[:destination_2]
    $transit_time_2 = session[:transit_time_2]
    # show_4の回答が終わりshow_5へ遷移したタイミングでスクレイピングのメソッドを呼び出す
    # session[:prefecture_to_live]に格納されている都県の値によって呼び出すメソッドを変える
    if session[:prefecture_to_live] == '東京都' #東京都のバリュー
      RentMarketPrice.search_destination_transit_time_tokyo
    elsif session[:prefecture_to_live] == '神奈川県' #神奈川県のバリュー
      RentMarketPrice.search_destination_transit_time_kanagawa
    elsif session[:prefecture_to_live] == '埼玉県' #埼玉県のバリュー
      RentMarketPrice.search_destination_transit_time_saitama
    elsif session[:prefecture_to_live] == '千葉県' #千葉県のバリュー
      RentMarketPrice.search_destination_transit_time_chiba
    end
    # スクレイピング終わりの$candidate_stationへ格納された内容をif文で条件分岐させる
    if $candidate_station == "条件にあう物件がありません。条件を変更して再度検索してください。"
      @not_candidate_station = $candidate_station
    elsif $candidate_station == "入力された駅名は存在しませんでした。駅名を変更いただき、再度検索してください。"
      @not_correct_station_name = $candidate_station
    else
      # 候補として取得した駅名$candidate_stationと希望する各条件を併せてwhereメソッドを使ってdbへデータの参照を行う
      # uniq!メソッドで配列内の重複要素を除去し直す
      infomations = RentMarketPrice.where(station_name: $candidate_station.uniq!).and(
                    RentMarketPrice.where("(market_price <= ?) AND (floor_plan = ?)", @rent_budget, @floor_plan)).and(
                    RentMarketPrice.where(gym: @gym, starbucks_coffee: @starbucks_coffee, mcdonalds: @mcdonalds, ohsho: @ohsho, supermarket: @supermarket, large_park: @large_park, library: @library, spa: @spa))
      @exactly_station = []
      # db参照の結果を出力する
      infomations.each do |info|
        @exactly_station << info.station_name + "駅"
      end
    end
  end
  # 質問項目に一通り回答した後に気になる駅情報を検索出来る様にするメソッド
  def set_search
    # gem ransackを導入してransackメソッドとresultメソッドを使えるようにする
    @q = RentMarketPrice.ransack(params[:q])
    @results = @q.result
  end
end
