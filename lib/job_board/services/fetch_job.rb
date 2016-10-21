# frozen_string_literal: true
require 'base64'
require 'job_board'
require_relative 'service'

module JobBoard
  module Services
    class FetchJob < Service
      def initialize(job_id: '', site: '')
        @job_id = job_id.to_s
        @site = site.to_s
      end

      attr_reader :job_id, :site

      def run
        return nil if job_id.empty? || site.empty?

        job = {}
        db_job = JobBoard::Models::Job.first(job_id: job_id, site: site)
        return nil unless db_job

        job.merge!(db_job.data)
        job.merge!(config.build.to_hash)
        job.merge!(config.cache_options.to_hash) unless
          config.cache_options.type.empty?

        job.merge(
          job_script: {
            name: 'main',
            encoding: 'base64',
            content: Base64.encode64(fetch_job_script(job)).split.join
          },
          job_state_url: JobBoard.config.fetch(:"job_state_#{site}_url"),
          log_parts_url: JobBoard.config.fetch(:"log_parts_#{site}_url"),
          jwt: generate_jwt(job),
          image_name: assign_image_name(job)
        )
      end

      def fetch_job_script(job)
        JobBoard::Services::FetchJobScript.run(job: job)
      end

      def generate_jwt(job)
        JobBoard::Services::CreateJWT.run(job_id: job.fetch('id'), site: site)
      end

      def assign_image_name(_job)
        # TODO: implement image name assignment
        'default'
      end

      def config
        JobBoard.config
      end
    end
  end
end
