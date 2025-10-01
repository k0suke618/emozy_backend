require "net/http"
require "uri"

module Api
  module V1
    class ReportController < ApplicationController
      # CSRF cookies are not present for external JSON clients
      skip_before_action :verify_authenticity_token
      # POST /api/v1/report
      def judge
        content = report_params[:content]
        result = judge_report(content)
        render json: result
      end

      private
      def report_params
        params.require(:report).permit(:content)
      end

      def judge_report(content)
        # python api を呼び出して判定
        # post http://localhost:8000/python/judge_report
        # リクエスト
        # { 
        #   report: { content: "..." }
        # }
        # 返り値
        # {
        # "is_report": true, # true: 不適切, false: 問題なし
        # response: "...", # 理由など
        # "detail": "..." # error等の詳細情報
        #}
        base_url = ENV.fetch("LLM_API_BASE", "http://localhost:8000")
        uri = URI.parse("#{base_url.chomp('/')}/python/judge_report")

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
          request.body = { message: content }.to_json
          http.request(request)
        end

        JSON.parse(response.body) # 返ってきた結果をそのまま返す
      rescue => e
        Rails.logger.error("Error in judge_report: #{e.class} #{e.message}")
        { "error" => "Error in judge_report", "detail" => e.message }
      end
    end
  end
end
