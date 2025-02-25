class ThumbnailsController < ApplicationController
  def generate
    begin
      unless [:width, :height, :url].all? {|key| params.key? key} 
        return render json: { error: { message: "Required parameter wasn't provided" }}, status: :bad_request
      end

      target_width = params[:width].to_i
      target_height = params[:height].to_i
      unless target_width > 0 && target_height > 0
        return render json: { error: { message: "width and height parameters should be positive integers" }}, 
                      status: :unprocessable_entity
      end 

      begin
        img = URI.open(params[:url]) { |f| Magick::Image.from_blob(f.read())[0] }
      rescue OpenURI::HTTPError => e 
        return render json: { error: { message: "URL argument isn't accessable" }},
                      status: :unprocessable_entity
      rescue Magick::ImageMagickError => e
        return render json: { error: { message: "URL argument isn't a link to processable image" }},
                      status: :unprocessable_entity
      end
      
      img.resize_to_fit!(target_width, target_height) if target_height < img.rows || target_width < img.columns
      img_with_background = Magick::Image.new(target_width, target_height) { |options| options.background_color = 'black' }
      img_with_background.composite!(img, Magick::CenterGravity, Magick::AtopCompositeOp)

      img_with_background.format = 'JPEG'
      binary_data = img_with_background.to_blob
      send_data binary_data, type: 'image/jpeg', disposition: 'inline'
    rescue StandardError => e
        render json: { error: { message: 'An error occurred while processing your request' }},
              status: :internal_server_error
        logger.error((["Unexpected error in #{self.class} - #{e.class}: #{e.message}"] + e.backtrace).join("\n"))
    end
  end
end
