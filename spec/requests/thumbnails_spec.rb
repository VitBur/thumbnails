require 'rails_helper'
require 'support/image_compare_helpers'


RSpec.configure do |config|
  config.include ImageCompareHelpers, :image_genarator
end


RSpec.describe 'Thumbnails', :image_genarator, type: :request do
  describe 'GET /thumbnail' do
    context 'with no params' do
      it 'returns HTTP status 400' do
        get thumbnail_path
        expect(response).to have_http_status(:bad_request)  
      end

      it 'returns error JSON' do
        get thumbnail_path
        expect(JSON.parse(response.body)).to eq(
          'error' => { 'message' => "Required parameter wasn't provided" }
        )
      end
    end

    it 'returns 400 without height param' do
      get thumbnail_path, params: {width: 100, url: 'https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2.png'}
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 400 without width param' do
      get thumbnail_path, params: {height: 100, url: 'https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2.png'}
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 400 without url param' do
      get thumbnail_path, params: {height: 100, width: 100 }
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 422 if height is negative' do
      get thumbnail_path, params: {width: 100, height: -12, url: 'https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2.png'}
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 if width is zero' do
      get thumbnail_path, params: {width: 0, height: 112, url: 'https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2.png'}
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 if host URL not accessible' do
      get thumbnail_path, params: {width: 123, height: 112, url: 'https://www.not-existing.url.cccc'}
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 if image not found' do
      get thumbnail_path, params: {width: 123, height: 112, url: 'https://www.google.com/not-existing'}
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 if not an image' do
      get thumbnail_path, params: {width: 123, height: 112, url: 'https://www.google.com'}
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context '40x70 thumbnail with white box 80x60 png image parameter' do
      let(:request_params) { { width: 40, height: 70, url: 'https://dummyimage.com/80x60/ffffff/fff.png' } }

      it 'returns with 200 status code' do 
        get thumbnail_path, params: request_params
        expect(response).to have_http_status(:success)
      end

      it 'returns response with content type image/jpeg' do 
        get thumbnail_path, params: request_params
        expect(response.content_type).to eq('image/jpeg')     # response type is ActionDispatch::TestResponsex
      end

      it 'returns an image with the requested dimensions' do 
        get thumbnail_path, params: request_params
        img = Magick::Image.from_blob(response.body).first
        expect(img.columns).to eq(40)
        expect(img.rows).to eq(70)
      end

      it 'returns image having black pixel in top left corner' do 
        get thumbnail_path, params: request_params
        img = Magick::Image.from_blob(response.body).first
        top_left_pixel = img.pixel_color(0, 0)
        expect(top_left_pixel.red).to eq(0)
        expect(top_left_pixel.green).to eq(0)
        expect(top_left_pixel.blue).to eq(0)
      end

      it 'returns image having a white pixel in (0, 35)' do 
        get thumbnail_path, params: request_params
        img = Magick::Image.from_blob(response.body).first
        pixel = img.pixel_color(0, 35)
        expect(pixel.red / 257).to eq(255)
        expect(pixel.green / 257).to eq(255)
        expect(pixel.blue / 257).to eq(255)
      end
    end

    it 'generates an image with low PSNR when request same width and height as original' do
      get thumbnail_path, params: {'width': 640, 'height': 427, 'url': 'https://res.cloudinary.com/demo/image/upload/docs/camera-640.jpg'}
      result = Magick::Image.from_blob(response.body).first
      original_image = URI.open('https://res.cloudinary.com/demo/image/upload/docs/camera-640.jpg') { |f|
        Magick::Image.from_blob(f.read())[0] 
      }
      
      expect(psnr(result, original_image)).to be > 40
    end
    
    context 'when we consider cloudinary output for a similar task as original, we get low PSNR for thumbnail' do
      example 'where black frame has to be created in both height and width' do
        get thumbnail_path, params: {'width': 525, 'height': 400, 'url': 'https://res.cloudinary.com/demo/image/upload/face_left.png'}
        result = Magick::Image.from_blob(response.body).first
        cloudinary_result = URI.open('https://res.cloudinary.com/demo/image/upload/b_black,h_400,c_lpad,w_525/face_left.png') { |f|
          Magick::Image.from_blob(f.read())[0] 
        }

        expect(psnr(result, cloudinary_result)).to be > 35
      end

      example 'where black frame has to be created in width' do
        get thumbnail_path, params: {'width': 400, 'height': 384, 'url': 'https://res.cloudinary.com/generative-ai-demos/image/upload/v1/website_assets/samples/fill/fill_3.jpg'}
        result = Magick::Image.from_blob(response.body).first
        cloudinary_result = URI.open('https://res.cloudinary.com/generative-ai-demos/image/upload/b_black,h_384,c_pad,w_400/v1/website_assets/samples/fill/fill_3.jpg') { |f|
          Magick::Image.from_blob(f.read())[0] 
        }

        expect(psnr(result, cloudinary_result)).to be > 35
      end

      example 'where black frame has to be created in height' do
        get thumbnail_path, params: {'width': 300, 'height': 500, 'url': 'https://digitalassets.tesla.com/tesla-contents/image/upload/24-7-monitoring-app-desktop'}
        result = Magick::Image.from_blob(response.body).first
        cloudinary_result = URI.open('https://digitalassets.tesla.com/tesla-contents/image/upload/w_300,h_500,c_pad,b_black/24-7-monitoring-app-desktop') { |f|
          Magick::Image.from_blob(f.read())[0] 
        }

        expect(psnr(result, cloudinary_result)).to be > 35
      end
    end
    
    
  end
end
