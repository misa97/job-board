# frozen_string_literal: true
require_relative 'image_params'
require_relative 'models'
require_relative 'services/update_image'

require 'l2met-log'

module JobBoard
  class ImageUpdater
    include L2met::Log

    def update(request_body)
      log level: :debug, msg: 'handling request',
          request_body: request_body.inspect

      images = []

      JobBoard::Models.db.transaction do
        images = request_body.split(/\n|\r\n/).map do |line|
          image = JobBoard::Services::UpdateImage.run(
            params: JobBoard::ImageParams.parse(line)
          )
          raise Sequel::Rollback if image.nil?
          image
        end
      end

      images.compact
    end
  end
end
